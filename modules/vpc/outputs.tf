output "network_id" {
  value = google_compute_network.this.id
}

output "network_self_link" {
  value = google_compute_network.this.self_link
}

output "network_name" {
  value = google_compute_network.this.name
}

output "workload_subnet_id" {
  value = google_compute_subnetwork.workload.id
}

output "connector_subnet_name" {
  value = google_compute_subnetwork.connector.name
}

output "connector_subnet_id" {
  value = google_compute_subnetwork.connector.id
}

output "ilb_frontend_ip" {
  value = var.reserve_ilb_ip ? google_compute_address.ilb_frontend[0].address : null
}

output "ilb_frontend_ip_id" {
  value = var.reserve_ilb_ip ? google_compute_address.ilb_frontend[0].id : null
}
