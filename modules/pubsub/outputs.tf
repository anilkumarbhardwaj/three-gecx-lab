output "topic_ids" {
  value = { for k, t in google_pubsub_topic.this : k => t.id }
}

output "dlq_topic_ids" {
  value = { for k, t in google_pubsub_topic.dlq : k => t.id }
}
