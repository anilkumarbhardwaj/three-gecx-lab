# Module: iam-bindings — group -> roles on a project (workbook sheet 02)

locals {
  pairs = flatten([
    for group, roles in var.group_roles : [
      for role in roles : {
        key    = "${group}--${role}"
        member = "group:${group}"
        role   = role
      }
    ]
  ])
}

resource "google_project_iam_member" "this" {
  for_each = { for p in local.pairs : p.key => p }
  project  = var.project_id
  role     = each.value.role
  member   = each.value.member
}
