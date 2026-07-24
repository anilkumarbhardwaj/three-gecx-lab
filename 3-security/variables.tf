variable "state_bucket" {
  type = string
}

variable "cicd_project_id" {
  type = string
}

variable "prefix" {
  type    = string
  default = "demo-lab"
}

variable "region" {
  type    = string
  default = "europe-west4"
}

variable "billing_account_id" {
  type = string
}

variable "tools" {
  description = "Tool adapter names — drives sm-{tool}-dev secrets (and 4-workload services)"
  type        = list(string)
  default     = ["billing", "orders", "write-financial"]
}

variable "alert_email" {
  description = "Ops notification email; empty = no channel/budget"
  type        = string
  default     = ""
}

variable "secops_group" {
  description = "gcp-gecx-secops group email for KMS admin; empty = skipped"
  type        = string
  default     = ""
}

variable "enable_dlp" {
  description = "Deploy DLP templates (requires dlp_wrapped_key)"
  type        = bool
  default     = false
}

variable "dlp_wrapped_key" {
  description = "Base64 KMS-wrapped DLP data key; empty = DLP templates skipped"
  type        = string
  default     = ""
  sensitive   = true
}

variable "terraform_service_account" {
  type    = string
  default = ""
}
