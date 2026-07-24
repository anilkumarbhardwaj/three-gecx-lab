# Module: kms — parity keyring + keys (workbook sheet 10)
# encrypterDecrypter -> service agents ONLY; admin -> secops group.
# No human ever gets encrypt/decrypt (separation of duties).

resource "google_kms_key_ring" "this" {
  project  = var.project_id
  name     = var.keyring_name
  location = var.region
}

resource "google_kms_crypto_key" "this" {
  for_each        = toset(var.key_names)
  key_ring        = google_kms_key_ring.this.id
  name            = each.value
  rotation_period = var.rotation_period

  destroy_scheduled_duration = var.destroy_scheduled_duration

  lifecycle {
    prevent_destroy = false # lab; true in real envs
  }
}

locals {
  encrypter_pairs = flatten([
    for key, members in var.key_encrypters : [
      for m in members : { k = "${key}--${m}", key = key, member = m }
    ]
  ])
}

resource "google_kms_crypto_key_iam_member" "encrypters" {
  for_each      = { for p in local.encrypter_pairs : p.k => p }
  crypto_key_id = google_kms_crypto_key.this[each.value.key].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = each.value.member
}

resource "google_kms_key_ring_iam_member" "admin" {
  count       = var.admin_group != "" ? 1 : 0
  key_ring_id = google_kms_key_ring.this.id
  role        = "roles/cloudkms.admin"
  member      = "group:${var.admin_group}"
}
