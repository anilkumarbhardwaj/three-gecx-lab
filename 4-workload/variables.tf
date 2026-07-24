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

variable "tools" {
  description = "Tool adapter names — must match 3-security so sm-{tool}-dev secrets exist"
  type        = list(string)
  default     = ["billing", "orders", "write-financial"]
}

variable "deploy_sa_email" {
  description = "sa-deploy-gecx-d email (Artifact Registry writer, sheet 16)"
  type        = string
}

variable "developers_group" {
  description = "gcp-gecx-developers group email for bucket viewer; empty = skipped"
  type        = string
  default     = ""
}

variable "enable_ilb" {
  description = "Build internal ALB + Service Directory webhook path (sheets 23/24)"
  type        = bool
  default     = false
}

variable "terraform_service_account" {
  type    = string
  default = ""
}
