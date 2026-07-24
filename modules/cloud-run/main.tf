# Module: cloud-run — tool adapter service shells (workbook sheet 20)
# Terraform owns the service shell; the CI pipeline owns image/revisions
# (lifecycle ignore_changes on image). Internal ingress only, per-tool SA,
# secret volume mounts, connector egress ALL_TRAFFIC -> firewall -> NAT.

resource "google_service_account" "tool" {
  for_each     = var.tools
  project      = var.project_id
  account_id   = "sa-run-${each.key}-${var.env_short}"
  display_name = "Cloud Run adapter — ${each.key}"
}

resource "google_cloud_run_v2_service" "this" {
  for_each = var.tools
  project  = var.project_id
  name     = "${var.name_prefix}-crun-${each.key}"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  deletion_protection = false # lab

  template {
    service_account = google_service_account.tool[each.key].email

    scaling {
      min_instance_count = each.value.min_instances
      max_instance_count = each.value.max_instances
    }

    max_instance_request_concurrency = each.value.concurrency
    timeout                          = "30s"

    dynamic "vpc_access" {
      for_each = var.connector_id != "" ? [1] : []
      content {
        connector = var.connector_id
        egress    = "ALL_TRAFFIC"
      }
    }

    containers {
      image = each.value.image

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      dynamic "volume_mounts" {
        for_each = length(each.value.secret_mounts) > 0 ? [1] : []
        content {
          name       = "secrets"
          mount_path = "/etc/secrets"
        }
      }

      startup_probe {
        http_get {
          path = "/healthz"
        }
        initial_delay_seconds = 5
        period_seconds        = 10
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/healthz"
        }
        period_seconds = 30
      }
    }

    dynamic "volumes" {
      for_each = length(each.value.secret_mounts) > 0 ? [1] : []
      content {
        name = "secrets"
        secret {
          secret = each.value.secret_mounts[0]
          dynamic "items" {
            for_each = each.value.secret_mounts
            content {
              path    = items.value
              version = "latest"
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image, # pipeline owns image/revisions
      client,
      client_version,
    ]
  }
}

# Invokers: agent runtime SA + ILB serverless NEG path only. Never allUsers.
resource "google_cloud_run_v2_service_iam_member" "invokers" {
  for_each = var.tools
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.this[each.key].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.runtime_invoker_sa}"
}

# Tool SA -> its own secret(s)
locals {
  secret_pairs = flatten([
    for tool, cfg in var.tools : [
      for s in cfg.secret_mounts : { k = "${tool}--${s}", tool = tool, secret = s }
    ]
  ])
}

resource "google_secret_manager_secret_iam_member" "tool_secrets" {
  for_each  = { for p in local.secret_pairs : p.k => p }
  project   = var.project_id
  secret_id = each.value.secret
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.tool[each.value.tool].email}"
}
