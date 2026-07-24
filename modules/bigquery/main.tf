# Module: bigquery — conv_raw + conv_curated (workbook sheet 18)
# Sheet 18 header: "Not Required anymore". Module retained for parity;
# wire it up only if the decision reopens.

resource "google_bigquery_dataset" "this" {
  for_each                   = var.datasets
  project                    = var.project_id
  dataset_id                 = each.key
  location                   = var.location
  default_table_expiration_ms = each.value.table_expiration_days != null ? each.value.table_expiration_days * 86400000 : null
  delete_contents_on_destroy = true # lab
  labels                     = { managed-by = "terraform" }
}

locals {
  access_pairs = flatten([
    for ds, cfg in var.datasets : concat(
      [for m in cfg.writers : { k = "${ds}--w--${m}", ds = ds, member = m, role = "roles/bigquery.dataEditor" }],
      [for m in cfg.readers : { k = "${ds}--r--${m}", ds = ds, member = m, role = "roles/bigquery.dataViewer" }]
    )
  ])
}

resource "google_bigquery_dataset_iam_member" "this" {
  for_each   = { for p in local.access_pairs : p.k => p }
  project    = var.project_id
  dataset_id = google_bigquery_dataset.this[each.value.ds].dataset_id
  role       = each.value.role
  member     = each.value.member
}
