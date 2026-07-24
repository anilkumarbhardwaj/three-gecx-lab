# Module: gcs — buckets (workbook sheet 15)
# UBLA + PAP enforced everywhere; versioning on; lifecycle to Nearline
# then delete; objectAdmin only for owning workload SAs.

resource "google_storage_bucket" "this" {
  for_each                    = var.buckets
  project                     = var.project_id
  name                        = each.key
  location                    = var.location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = var.force_destroy

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = each.value.nearline_age_days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = each.value.delete_age_days
    }
    action {
      type = "Delete"
    }
  }

  dynamic "encryption" {
    for_each = each.value.kms_key_id != "" ? [1] : []
    content {
      default_kms_key_name = each.value.kms_key_id
    }
  }

  labels = { managed-by = "terraform" }
}

locals {
  admin_pairs = flatten([
    for b, cfg in var.buckets : [
      for m in cfg.object_admins : { k = "${b}--admin--${m}", bucket = b, member = m, role = "roles/storage.objectAdmin" }
    ]
  ])
  viewer_pairs = flatten([
    for b, cfg in var.buckets : [
      for m in cfg.viewers : { k = "${b}--view--${m}", bucket = b, member = m, role = "roles/storage.objectViewer" }
    ]
  ])
}

resource "google_storage_bucket_iam_member" "this" {
  for_each = { for p in concat(local.admin_pairs, local.viewer_pairs) : p.k => p }
  bucket   = google_storage_bucket.this[each.value.bucket].name
  role     = each.value.role
  member   = each.value.member
}
