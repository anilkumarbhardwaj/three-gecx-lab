output "private_zone_name" {
  value = google_dns_managed_zone.private.name
}

output "private_zone_dns_name" {
  value = google_dns_managed_zone.private.dns_name
}
