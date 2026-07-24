# Module: project — folder + project + API enablement (workbook sheet 01)

resource "google_folder" "this" {
  count        = var.create_folder ? 1 : 0
  display_name = var.folder_display_name
  parent       = var.folder_parent
}

locals {
  folder_id = var.create_folder ? google_folder.this[0].name : var.existing_folder_id
}

resource "google_project" "this" {
  name            = var.project_name
  project_id      = var.project_id
  folder_id       = local.folder_id
  billing_account = var.billing_account_id
  deletion_policy = var.deletion_policy
  labels          = var.labels
}

resource "google_project_service" "this" {
  for_each           = toset(var.activate_apis)
  project            = google_project.this.project_id
  service            = each.value
  disable_on_destroy = false
}
