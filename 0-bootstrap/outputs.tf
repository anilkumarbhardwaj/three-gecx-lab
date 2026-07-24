output "gecx_folder_id" {
  value = google_folder.gecx.name # format: folders/123456789
}

output "cicd_project_id" {
  value = google_project.cicd.project_id
}

output "state_bucket" {
  value = google_storage_bucket.tfstate.name
}

output "sa_tf_foundation" {
  value = google_service_account.tf_foundation.email
}

output "sa_tf_workloads" {
  value = google_service_account.tf_workloads.email
}

output "wif_provider" {
  description = "Set as GitHub repo variable GCP_WIF_PROVIDER"
  value       = google_iam_workload_identity_pool_provider.github.name
}
