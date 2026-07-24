# Module: pubsub — event topics + DLQs (workbook sheet 17)
# Each topic gets: Avro schema (REJECT invalid), a <name>-dlq topic,
# and a pull subscription wired with dead_letter_policy.

resource "google_pubsub_schema" "this" {
  for_each   = { for k, v in var.topics : k => v if v.avro_schema != "" }
  project    = var.project_id
  name       = "${each.key}-schema"
  type       = "AVRO"
  definition = each.value.avro_schema
}

resource "google_pubsub_topic" "this" {
  for_each                   = var.topics
  project                    = var.project_id
  name                       = each.key
  message_retention_duration = each.value.retention

  dynamic "schema_settings" {
    for_each = each.value.avro_schema != "" ? [1] : []
    content {
      schema   = google_pubsub_schema.this[each.key].id
      encoding = "JSON"
    }
  }
}

resource "google_pubsub_topic" "dlq" {
  for_each                   = var.topics
  project                    = var.project_id
  name                       = "${each.key}-dlq"
  message_retention_duration = "1209600s" # 14d
}

resource "google_pubsub_subscription" "this" {
  for_each = var.topics
  project  = var.project_id
  name     = "${each.key}-sub"
  topic    = google_pubsub_topic.this[each.key].id

  ack_deadline_seconds = 30

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dlq[each.key].id
    max_delivery_attempts = 5
  }

  retry_policy {
    minimum_backoff = "10s"
  }
}

resource "google_pubsub_subscription" "dlq_monitor" {
  for_each = var.topics
  project  = var.project_id
  name     = "${each.key}-dlq-sub"
  topic    = google_pubsub_topic.dlq[each.key].id
}

# Pub/Sub service agent must publish to DLQ / subscribe on source
resource "google_pubsub_topic_iam_member" "dlq_publisher" {
  for_each = var.topics
  project  = var.project_id
  topic    = google_pubsub_topic.dlq[each.key].name
  role     = "roles/pubsub.publisher"
  member   = "serviceAccount:service-${var.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_subscription_iam_member" "dlq_subscriber" {
  for_each     = var.topics
  project      = var.project_id
  subscription = google_pubsub_subscription.this[each.key].name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:service-${var.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}
