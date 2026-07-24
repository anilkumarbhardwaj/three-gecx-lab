output "bucket_names" {
  value = module.gcs.bucket_names
}

output "artifact_registry_url" {
  value = module.artifact_registry.repository_url
}

output "cloud_run_services" {
  value = module.cloud_run.service_names
}

output "webhook_service_resource" {
  description = "Paste into the CES webhook config (agent-config pipeline, sheet 23)"
  value       = var.enable_ilb ? module.service_directory[0].webhook_service_resource : null
}
