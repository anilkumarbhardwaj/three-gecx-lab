output "service_names" {
  value = { for k, s in google_cloud_run_v2_service.this : k => s.name }
}

output "service_uris" {
  value = { for k, s in google_cloud_run_v2_service.this : k => s.uri }
}

output "tool_sa_emails" {
  value = { for k, sa in google_service_account.tool : k => sa.email }
}
