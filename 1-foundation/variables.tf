variable "org_id" {
  type = string
}

variable "billing_account_id" {
  type = string
}

variable "prefix" {
  type = string
}

variable "gecx_folder_id" {
  description = "From bootstrap output, format folders/123456789"
  type        = string
}

variable "cicd_project_id" {
  type = string
}

variable "terraform_service_account" {
  description = "sa-tf-foundation email; empty string to use your own ADC"
  type        = string
  default     = ""
}

variable "environments" {
  description = "Lab uses two envs to save free-tier project quota; 3IR uses dev/preprod/prod"
  type        = list(string)
  default     = ["dev", "prod"]
}
