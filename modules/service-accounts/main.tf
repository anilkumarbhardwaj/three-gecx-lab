# Module: service-accounts — workload identities (workbook sheet 03)

resource "google_service_account" "this" {
  for_each     = var.service_accounts
  project      = var.project_id
  account_id   = each.key
  display_name = each.value.display_name
}

locals {
  role_pairs = flatten([
    for sa_id, sa in var.service_accounts : [
      for role in sa.project_roles : {
        key   = "${sa_id}--${role}"
        sa_id = sa_id
        role  = role
      }
    ]
  ])
}

resource "google_project_iam_member" "this" {
  for_each = { for p in local.role_pairs : p.key => p }
  project  = var.project_id
  role     = each.value.role
  member   = "serviceAccount:${google_service_account.this[each.value.sa_id].email}"
}
