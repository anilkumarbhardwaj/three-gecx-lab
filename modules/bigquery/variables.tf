variable "project_id" {
  type = string
}

variable "location" {
  type = string
}

variable "datasets" {
  type = map(object({
    table_expiration_days = optional(number)
    writers               = optional(list(string), [])
    readers               = optional(list(string), [])
  }))
  default = {}
}
