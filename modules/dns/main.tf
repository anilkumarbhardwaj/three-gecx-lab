# Module: dns — private authoritative zone + Google API zones (workbook sheet 07)
# 3IR delegates googleapis.com / gcr.io / pkg.dev to the Transit Hub via
# peering zones. The lab has no hub, so when create_google_api_zones = true
# we build the equivalent private zones locally (restricted.googleapis.com
# 199.36.153.8/30 — same PGA outcome).

# Authoritative private zone, e.g. dev.cxai.three.ie
resource "google_dns_managed_zone" "private" {
  project     = var.project_id
  name        = var.private_zone_name
  dns_name    = "${var.private_zone_domain}."
  description = "CXAI service records: ILB, api endpoints"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = var.network_id
    }
  }
}

# e.g. api.gecx.dev.cxai.three.ie -> ILB internal IP
resource "google_dns_record_set" "records" {
  for_each     = var.a_records
  project      = var.project_id
  managed_zone = google_dns_managed_zone.private.name
  name         = "${each.key}.${var.private_zone_domain}."
  type         = "A"
  ttl          = 300
  rrdatas      = [each.value]
}

# --- Private Google Access zones (hub-peering substitute) --------------------

locals {
  api_zones = var.create_google_api_zones ? {
    googleapis = "googleapis.com."
    gcr        = "gcr.io."
    pkgdev     = "pkg.dev."
  } : {}
  restricted_vips = ["199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"]
}

resource "google_dns_managed_zone" "google_apis" {
  for_each    = local.api_zones
  project     = var.project_id
  name        = "${var.zone_name_prefix}-${each.key}"
  dns_name    = each.value
  description = "Private path to Google APIs (lab substitute for hub peering zone)"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = var.network_id
    }
  }
}

resource "google_dns_record_set" "restricted_a" {
  for_each     = local.api_zones
  project      = var.project_id
  managed_zone = google_dns_managed_zone.google_apis[each.key].name
  name         = each.key == "googleapis" ? "restricted.googleapis.com." : each.value
  type         = "A"
  ttl          = 300
  rrdatas      = local.restricted_vips
}

resource "google_dns_record_set" "wildcard_cname" {
  for_each     = local.api_zones
  project      = var.project_id
  managed_zone = google_dns_managed_zone.google_apis[each.key].name
  name         = "*.${each.value}"
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["restricted.googleapis.com."]
}
