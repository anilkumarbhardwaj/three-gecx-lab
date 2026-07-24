output "forwarding_rule_ip" {
  value = google_compute_forwarding_rule.this.ip_address
}
