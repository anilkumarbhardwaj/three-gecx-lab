output "project_ids" {
  value = { for env, p in google_project.gecx : env => p.project_id }
}

output "env_folder_ids" {
  value = { for k, f in google_folder.env : k => f.name }
}
