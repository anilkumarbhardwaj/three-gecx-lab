variable "state_bucket" {
  type = string
}

variable "cicd_project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west4"
}

variable "enable_nat" {
  description = "Router+NAT+static IP bill hourly — enable only while testing"
  type        = bool
  default     = false
}

variable "enable_vpc_connector" {
  description = "Connector instances bill hourly — enable only while testing"
  type        = bool
  default     = false
}

variable "soa_gateway_cidrs" {
  description = "3IR SOA public gateway IPs (fw rule 500); empty until confirmed"
  type        = list(string)
  default     = []
}

variable "terraform_service_account" {
  type    = string
  default = ""
}
