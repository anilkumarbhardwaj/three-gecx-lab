variable "project_id" {
  type = string
}

variable "service_accounts" {
  description = "account_id -> { display_name, project_roles }"
  type = map(object({
    display_name  = string
    project_roles = optional(list(string), [])
  }))
  default = {}
}
