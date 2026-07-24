output "kms_key_ids" {
  value = module.kms.key_ids
}

output "secret_ids" {
  value = module.secrets.secret_ids
}
