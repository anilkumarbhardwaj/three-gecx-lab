output "nat_static_ips" {
  description = "Register these in the IP register / 3IR gateway allowlist"
  value       = google_compute_address.nat[*].address
}

output "router_name" {
  value = google_compute_router.this.name
}
