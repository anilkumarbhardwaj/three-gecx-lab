variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "keyring_name" {
  type = string
}

variable "key_names" {
  type = list(string)
}

variable "rotation_period" {
  description = "90 days"
  type        = string
  default     = "7776000s"
}

variable "destroy_scheduled_duration" {
  description = "30 days"
  type        = string
  default     = "2592000s"
}

variable "key_encrypters" {
  description = "key name -> list of IAM members (service agents only)"
  type        = map(list(string))
  default     = {}
}

variable "admin_group" {
  description = "secops group email; empty to skip"
  type        = string
  default     = ""
}
