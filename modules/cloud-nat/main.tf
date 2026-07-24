# Module: cloud-nat — Router + NAT + static egress IP (workbook sheet 05)
# NAT anchor only: no BGP, no peers. Static IP is shared with 3IR for
# gateway allowlisting, hence MANUAL_ONLY allocation.

resource "google_compute_router" "this" {
  project = var.project_id
  name    = var.router_name
  region  = var.region
  network = var.network_id

  bgp {
    asn = 64514 # value irrelevant — NAT anchor only
  }
}

resource "google_compute_address" "nat" {
  count        = var.nat_ip_count
  project      = var.project_id
  name         = var.nat_ip_count == 1 ? var.nat_ip_name : "${var.nat_ip_name}-${count.index + 1}"
  region       = var.region
  address_type = "EXTERNAL"
}

resource "google_compute_router_nat" "this" {
  project = var.project_id
  name    = var.nat_name
  router  = google_compute_router.this.name
  region  = var.region

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.nat[*].self_link

  # Workload + connector subnets only — proxy/PSC subnets never NAT
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  dynamic "subnetwork" {
    for_each = var.nat_subnet_ids
    content {
      name                    = subnetwork.value
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }

  min_ports_per_vm = var.min_ports_per_vm

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
