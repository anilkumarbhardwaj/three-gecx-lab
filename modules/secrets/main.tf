# Module: secrets — Secret Manager shells (workbook sheet 11)
# Shells only: values are NEVER in terraform state — versions are added
# manually or by CI (`gcloud secrets versions add`).

resource "google_pubsub_topic" "rotation" {
  count   = var.rotation_topic_name != "" ? 1 : 0
  project = var.project_id
  name    = var.rotation_topic_name
}

# Secret Manager service agent must be able to publish rotation reminders
resource "google_pubsub_topic_iam_member" "sm_publisher" {
  count   = var.rotation_topic_name != "" ? 1 : 0
  project = var.project_id
  topic   = google_pubsub_topic.rotation[0].name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-secretmanager.iam.gserviceaccount.com"
}

resource "google_secret_manager_secret" "this" {
  for_each  = var.secrets
  project   = var.project_id
  secret_id = each.key

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  dynamic "rotation" {
    for_each = var.rotation_topic_name != "" ? [1] : []
    content {
      rotation_period    = var.rotation_period
      next_rotation_time = timeadd(timestamp(), "2160h") # first reminder in 90d
    }
  }

  dynamic "topics" {
    for_each = var.rotation_topic_name != "" ? [1] : []
    content {
      name = google_pubsub_topic.rotation[0].id
    }
  }

  labels = { managed-by = "terraform" }

  lifecycle {
    ignore_changes = [rotation] # timestamp() would churn every plan
  }

  depends_on = [google_pubsub_topic_iam_member.sm_publisher]
}

locals {
  accessor_pairs = flatten([
    for secret, members in var.secrets : [
      for m in members.accessors : { k = "${secret}--${m}", secret = secret, member = m }
    ]
  ])
}

resource "google_secret_manager_secret_iam_member" "accessors" {
  for_each  = { for p in local.accessor_pairs : p.k => p }
  project   = var.project_id
  secret_id = google_secret_manager_secret.this[each.value.secret].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value.member
}
