variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "inspect_template_name" {
  type    = string
  default = "cxai-gecx-inspect"
}

variable "deidentify_template_name" {
  type    = string
  default = "cxai-gecx-deidentify"
}

variable "info_types" {
  description = "Sheet 14: MSISDN(=PHONE_NUMBER), PPSN(=IRELAND_PPSN), IBAN, PAN(=CREDIT_CARD_NUMBER), email, EIRCODE"
  type        = list(string)
  default = [
    "PHONE_NUMBER",
    "IRELAND_PPSN",
    "IBAN_CODE",
    "CREDIT_CARD_NUMBER",
    "EMAIL_ADDRESS",
    "IRELAND_EIRCODE",
  ]
}

variable "kms_key_id" {
  type = string
}

variable "wrapped_key" {
  description = "Base64 KMS-wrapped data key (generate out-of-band; placeholder in lab)"
  type        = string
  sensitive   = true
}
