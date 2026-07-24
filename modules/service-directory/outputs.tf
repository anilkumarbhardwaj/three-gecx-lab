output "webhook_service_resource" {
  description = "Use this resource name in the CES webhook config (agent-config pipeline)"
  value       = google_service_directory_service.webhook.id
}
