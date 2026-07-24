# Module: logging — buckets, sinks, audit config, log metrics (sheet 12)

# _Default bucket retention (dev 30d; prod 400d locked)
resource "google_logging_project_bucket_config" "default" {
  project        = var.project_id
  location       = var.log_bucket_location
  bucket_id      = "_Default"
  retention_days = var.retention_days
}

# Aggregated sink -> platform logging destination (lab: central audit bucket)
resource "google_logging_project_sink" "central" {
  count                  = var.sink_destination != "" ? 1 : 0
  project                = var.project_id
  name                   = var.sink_name
  destination            = var.sink_destination
  filter                 = "logName:\"cloudaudit.googleapis.com\" OR severity>=ERROR"
  unique_writer_identity = true
}

# Data Access audit logs — READ+WRITE, no exempt members
resource "google_project_iam_audit_config" "data_access" {
  for_each = toset(var.data_access_services)
  project  = var.project_id
  service  = each.value

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

# Log-based metrics (sheet 12)
resource "google_logging_metric" "this" {
  for_each = var.log_metrics
  project  = var.project_id
  name     = each.key
  filter   = each.value

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
