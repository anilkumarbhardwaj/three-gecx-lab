# Module: monitoring — alert policies + budget (workbook sheet 13)

resource "google_monitoring_notification_channel" "email" {
  count        = var.alert_email != "" ? 1 : 0
  project      = var.project_id
  display_name = "Ops email"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}

locals {
  channels = var.alert_email != "" ? [google_monitoring_notification_channel.email[0].id] : []
}

# Cloud Run 5xx > threshold over 5 min (dev 5%; prod 1%)
resource "google_monitoring_alert_policy" "run_5xx" {
  project      = var.project_id
  display_name = "Cloud Run 5xx ratio"
  combiner     = "OR"

  conditions {
    display_name = "5xx > ${var.run_5xx_threshold * 100}% over 5m"
    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class = \"5xx\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.run_5xx_threshold
      duration        = "300s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = local.channels
}

# Serverless connector instances pinned at max for 10 min
resource "google_monitoring_alert_policy" "connector_saturation" {
  project      = var.project_id
  display_name = "VPC connector saturation"
  combiner     = "OR"

  conditions {
    display_name = "Instances at max for 10m"
    condition_threshold {
      filter          = "resource.type = \"vpc_access_connector\" AND metric.type = \"vpcaccess.googleapis.com/connector/instances\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.connector_max_instances - 1
      duration        = "600s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = local.channels
}

# NAT port allocation failures > 0 — internet egress health (NEW, sheet 13)
resource "google_monitoring_alert_policy" "nat_allocation" {
  project      = var.project_id
  display_name = "NAT allocation failed"
  combiner     = "OR"

  conditions {
    display_name = "nat_allocation_failed > 0"
    condition_threshold {
      filter          = "resource.type = \"nat_gateway\" AND metric.type = \"router.googleapis.com/nat/nat_allocation_failed\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = local.channels
}

# Budget: 50/80/100% -> email via billing budget notifications
resource "google_billing_budget" "this" {
  count           = var.create_budget ? 1 : 0
  billing_account = var.billing_account_id
  display_name    = "budget-${var.project_id}"

  budget_filter {
    projects = ["projects/${var.project_number}"]
  }

  amount {
    specified_amount {
      currency_code = var.budget_currency
      units         = tostring(var.budget_amount)
    }
  }

  dynamic "threshold_rules" {
    for_each = [0.5, 0.8, 1.0]
    content {
      threshold_percent = threshold_rules.value
      spend_basis       = "CURRENT_SPEND"
    }
  }

  dynamic "all_updates_rule" {
    for_each = length(local.channels) > 0 ? [1] : []
    content {
      monitoring_notification_channels = local.channels
      disable_default_iam_recipients   = false
    }
  }
}
