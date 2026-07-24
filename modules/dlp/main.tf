# Module: dlp — inspect + de-identify templates (workbook sheet 14)

resource "google_data_loss_prevention_inspect_template" "this" {
  parent       = "projects/${var.project_id}/locations/${var.region}"
  display_name = var.inspect_template_name
  description  = "PII infoTypes for CXAI conversations"

  inspect_config {
    dynamic "info_types" {
      for_each = var.info_types
      content {
        name = info_types.value
      }
    }
    min_likelihood = "POSSIBLE"
  }
}

# Crypto-hash de-identification — consistent tokens so joins survive
# without raw PII. KMS-wrapped key supplied out-of-band (never in state).
resource "google_data_loss_prevention_deidentify_template" "this" {
  parent       = "projects/${var.project_id}/locations/${var.region}"
  display_name = var.deidentify_template_name
  description  = "Crypto-hash with KMS-wrapped key; joins survive without raw PII"

  deidentify_config {
    info_type_transformations {
      transformations {
        primitive_transformation {
          crypto_hash_config {
            crypto_key {
              kms_wrapped {
                wrapped_key     = var.wrapped_key
                crypto_key_name = var.kms_key_id
              }
            }
          }
        }
      }
    }
  }
}
