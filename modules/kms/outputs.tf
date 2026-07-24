output "keyring_id" {
  value = google_kms_key_ring.this.id
}

output "key_ids" {
  value = { for k, key in google_kms_crypto_key.this : k => key.id }
}
