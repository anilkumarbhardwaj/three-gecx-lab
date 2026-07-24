output "project_id" {
  value = google_project.this.project_id
}

output "project_number" {
  value = google_project.this.number
}

output "folder_id" {
  value = local.folder_id
}

output "enabled_apis" {
  value = [for s in google_project_service.this : s.service]
}
