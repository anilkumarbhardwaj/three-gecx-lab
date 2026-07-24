variable "org_id" {
  description = "Numeric organization ID (gcloud organizations list)"
  type        = string
}

variable "billing_account_id" {
  description = "Billing account ID, format XXXXXX-XXXXXX-XXXXXX (gcloud billing accounts list)"
  type        = string
}

variable "prefix" {
  description = "Globally-unique short prefix for project IDs and bucket names, e.g. anb7"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,7}$", var.prefix))
    error_message = "Lowercase alphanumeric, 3-8 chars, starting with a letter."
  }
}

variable "region" {
  description = "Primary region (EU to mirror 3IR residency posture)"
  type        = string
  default     = "europe-west1"
}

variable "github_repository" {
  description = "GitHub repo allowed to deploy via WIF, format: <username>/<repo>, e.g. anilbhardwaj/three-gecx-lab"
  type        = string
}

variable "quota_project_id" {
  description = "Optional: existing project for API quota during first apply. Leave empty on first run."
  type        = string
  default     = ""
}
