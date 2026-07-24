variable "create_folder" {
  type    = bool
  default = true
}

variable "folder_display_name" {
  type    = string
  default = ""
}

variable "folder_parent" {
  description = "organizations/NNN or folders/NNN"
  type        = string
  default     = ""
}

variable "existing_folder_id" {
  description = "folders/NNN — used when create_folder = false"
  type        = string
  default     = ""
}

variable "project_name" {
  type = string
}

variable "project_id" {
  type = string
}

variable "billing_account_id" {
  type = string
}

variable "deletion_policy" {
  description = "Workbook says PREVENT; lab default DELETE so teardown works"
  type        = string
  default     = "DELETE"
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "activate_apis" {
  type    = list(string)
  default = []
}
