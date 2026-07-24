# Module: vpc — VPC + subnets + reserved ILB IP (workbook sheet 04)

resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Workload subnet — PGA on, flow logs per LZ policy
resource "google_compute_subnetwork" "workload" {
  project                  = var.project_id
  name                     = var.workload_subnet.name
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = var.workload_subnet.cidr
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.1
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Serverless VPC Access connector subnet — must be exactly /28
resource "google_compute_subnetwork" "connector" {
  project                  = var.project_id
  name                     = var.connector_subnet.name
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = var.connector_subnet.cidr
  private_ip_google_access = true
}

# Private Service Connect subnet
resource "google_compute_subnetwork" "psc" {
  count         = var.psc_subnet != null ? 1 : 0
  project       = var.project_id
  name          = var.psc_subnet.name
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = var.psc_subnet.cidr
  purpose       = "PRIVATE_SERVICE_CONNECT"
}

# Proxy-only subnet — required for the regional internal ALB (sheet 24)
resource "google_compute_subnetwork" "proxy_only" {
  count         = var.proxy_only_subnet != null ? 1 : 0
  project       = var.project_id
  name          = var.proxy_only_subnet.name
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = var.proxy_only_subnet.cidr
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# Reserved static internal IP for the ILB frontend
resource "google_compute_address" "ilb_frontend" {
  count        = var.reserve_ilb_ip ? 1 : 0
  project      = var.project_id
  name         = var.ilb_ip_name
  region       = var.region
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.workload.id
  purpose      = "SHARED_LOADBALANCER_VIP"
}
