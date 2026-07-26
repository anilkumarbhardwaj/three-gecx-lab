# Module: internal-alb — regional internal Application LB (workbook sheet 24)
# fwd rule -> HTTPS target proxy -> URL map -> per-tool backend services
# -> serverless NEGs -> Cloud Run adapters. Uses the proxy-only subnet
# from the vpc module. Serverless NEGs need no LB health check — Cloud Run
# startup/liveness probes cover it (sheet 20/24).

# Self-managed regional cert. Lab: self-signed via the tls provider.
# Real env: cert issued from Three internal CA / ACME.
resource "tls_private_key" "this" {
  count     = var.create_self_signed_cert ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "this" {
  count           = var.create_self_signed_cert ? 1 : 0
  private_key_pem = tls_private_key.this[0].private_key_pem

  subject {
    common_name  = var.certificate_domain
    organization = "demo-lab"
  }

  dns_names             = [var.certificate_domain]
  validity_period_hours = 8760

  allowed_uses = ["key_encipherment", "digital_signature", "server_auth"]
}

resource "google_compute_region_ssl_certificate" "this" {
  count       = var.create_self_signed_cert ? 1 : 0
  project     = var.project_id
  region      = var.region
  name        = var.certificate_name
  private_key = tls_private_key.this[0].private_key_pem
  certificate = tls_self_signed_cert.this[0].cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

# One serverless NEG per Cloud Run adapter
resource "google_compute_region_network_endpoint_group" "neg" {
  for_each              = var.backends
  project               = var.project_id
  region                = var.region
  name                  = "${var.name_prefix}-neg-${each.key}-${var.region_short}"
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = each.value.cloud_run_service
  }
}

resource "google_compute_region_backend_service" "bes" {
  for_each              = var.backends
  project               = var.project_id
  region                = var.region
  name                  = "${var.name_prefix}-bes-${each.key}-${var.region_short}"
  load_balancing_scheme = "INTERNAL_MANAGED"
  protocol              = "HTTPS"
  timeout_sec           = 30 # aligned to Cloud Run timeout

  backend {
    group           = google_compute_region_network_endpoint_group.neg[each.key].id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 1.0 # dev
  }
}

# Path-based routing: /tools/{tool}/* -> per-tool backend
resource "google_compute_region_url_map" "this" {
  project         = var.project_id
  region          = var.region
  name            = "${var.name_prefix}-um-${var.region_short}"
  default_service = google_compute_region_backend_service.bes[var.default_backend].id

  host_rule {
    hosts        = [var.certificate_domain]
    path_matcher = "tools"
  }

  path_matcher {
    name            = "tools"
    default_service = google_compute_region_backend_service.bes[var.default_backend].id

    dynamic "path_rule" {
      for_each = var.backends
      content {
        paths   = [path_rule.value.path]
        service = google_compute_region_backend_service.bes[path_rule.key].id
      }
    }
  }
}

resource "google_compute_region_target_https_proxy" "this" {
  project          = var.project_id
  region           = var.region
  name             = "${var.name_prefix}-thp-${var.region_short}"
  url_map          = google_compute_region_url_map.this.id
  ssl_certificates = var.create_self_signed_cert ? [google_compute_region_ssl_certificate.this[0].id] : var.ssl_certificate_ids
}

resource "google_compute_forwarding_rule" "this" {
  project               = var.project_id
  region                = var.region
  name                  = "${var.name_prefix}-fr-${var.region_short}"
  load_balancing_scheme = "INTERNAL_MANAGED"
  ip_protocol           = "TCP"
  port_range            = "443"
  network               = var.network_id
  subnetwork            = var.workload_subnet_id
  ip_address            = var.ilb_ip_id
  target                = google_compute_region_target_https_proxy.this.id
}
