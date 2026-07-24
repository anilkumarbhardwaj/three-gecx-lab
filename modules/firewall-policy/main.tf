# Module: firewall-policy — global network firewall policy, zero-trust
# (workbook sheet 08). Default-deny egress floor; explicit allows only.

resource "google_compute_network_firewall_policy" "this" {
  project     = var.project_id
  name        = var.policy_name
  description = "Zero-trust policy per HLD 8.1.1 — tag-driven rules"
}

resource "google_compute_network_firewall_policy_association" "this" {
  project           = var.project_id
  name              = "${var.policy_name}-assoc"
  firewall_policy   = google_compute_network_firewall_policy.this.name
  attachment_target = var.network_id
}

# --- Ingress -----------------------------------------------------------------

# 100 — IAP TCP forwarding (tagged mgmt; expect unused)
resource "google_compute_network_firewall_policy_rule" "allow_iap" {
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.this.name
  priority        = 100
  direction       = "INGRESS"
  action          = "allow"
  description     = "IAP TCP forwarding"
  match {
    src_ip_ranges = ["35.235.240.0/20"]
    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["22"]
    }
  }
}

# 200 — Google LB health checks
resource "google_compute_network_firewall_policy_rule" "allow_health_checks" {
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.this.name
  priority        = 200
  direction       = "INGRESS"
  action          = "allow"
  description     = "GCLB health check ranges -> ILB backends"
  match {
    src_ip_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
    layer4_configs {
      ip_protocol = "tcp"
    }
  }
}

# 300 — Service Directory Private Network Access (sheet 23 dependency)
resource "google_compute_network_firewall_policy_rule" "allow_sd_pna" {
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.this.name
  priority        = 300
  direction       = "INGRESS"
  action          = "allow"
  description     = "Service Directory PNA range -> ILB frontend 443; without it webhook calls silently fail"
  match {
    src_ip_ranges = ["35.199.192.0/19"]
    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["443"]
    }
  }
}

# 400 — deny cross-env (logged)
resource "google_compute_network_firewall_policy_rule" "deny_cross_env" {
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.this.name
  priority        = 400
  direction       = "INGRESS"
  action          = "deny"
  description     = "Env isolation — other env CIDRs are denied and logged"
  enable_logging  = true
  match {
    src_ip_ranges = var.cross_env_cidrs
    layer4_configs {
      ip_protocol = "all"
    }
  }
}

# --- Egress (internet path for SOA) ------------------------------------------

# 500 — SOA public gateway over NAT
resource "google_compute_network_firewall_policy_rule" "allow_soa" {
  count           = length(var.soa_gateway_cidrs) > 0 ? 1 : 0
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.this.name
  priority        = 500
  direction       = "EGRESS"
  action          = "allow"
  description     = "3IR SOA public gateway via Cloud NAT (replaces on-prem SOA rule)"
  match {
    dest_ip_ranges = var.soa_gateway_cidrs
    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["443"]
    }
  }
}

# 510 — Private Google Access (restricted VIP)
resource "google_compute_network_firewall_policy_rule" "allow_pga" {
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.this.name
  priority        = 510
  direction       = "EGRESS"
  action          = "allow"
  description     = "restricted.googleapis.com VIP"
  match {
    dest_ip_ranges = ["199.36.153.8/30"]
    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["443"]
    }
  }
}

# 520 — tagged internet egress (Five9 / 3rd parties / SOA-bound adapters)
resource "google_compute_network_firewall_policy_rule" "allow_tagged_egress" {
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.this.name
  priority        = 520
  direction       = "EGRESS"
  action          = "allow"
  description     = "0.0.0.0/0:443 for workloads carrying the egress=external-api secure tag"
  match {
    dest_ip_ranges = ["0.0.0.0/0"]
    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["443"]
    }
    dynamic "src_secure_tags" {
      for_each = var.egress_secure_tag != "" ? [var.egress_secure_tag] : []
      content {
        name = src_secure_tags.value
      }
    }
  }
}

# 65534 — deny-all egress, logged (zero-trust floor)
resource "google_compute_network_firewall_policy_rule" "deny_all_egress" {
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.this.name
  priority        = 65534
  direction       = "EGRESS"
  action          = "deny"
  description     = "Zero-trust floor per HLD 8.1.1"
  enable_logging  = true
  match {
    dest_ip_ranges = ["0.0.0.0/0"]
    layer4_configs {
      ip_protocol = "all"
    }
  }
}
