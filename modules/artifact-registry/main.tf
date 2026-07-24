# Module: artifact-registry — docker repo for adapter images (sheet 16)
# Immutable tags, untagged cleanup > 30d, writer = deploy SA (WIF),
# reader = Cloud Run service agent.

resource "google_artifact_registry_repository" "this" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = "Adapter images land here from CI"

  docker_config {
    immutable_tags = true
  }

  cleanup_policies {
    id     = "delete-untagged-30d"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "2592000s"
    }
  }

  labels = { managed-by = "terraform" }
}

resource "google_artifact_registry_repository_iam_member" "writers" {
  for_each   = toset(var.writers)
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.this.repository_id
  role       = "roles/artifactregistry.writer"
  member     = each.value
}

resource "google_artifact_registry_repository_iam_member" "readers" {
  for_each   = toset(var.readers)
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.this.repository_id
  role       = "roles/artifactregistry.reader"
  member     = each.value
}
