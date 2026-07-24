variable "project_id" {
  type = string
}

variable "group_roles" {
  description = "Map of group email -> list of roles"
  type        = map(list(string))
  default     = {}
}
