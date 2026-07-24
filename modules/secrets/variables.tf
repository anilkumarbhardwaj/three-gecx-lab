variable "project_id" {
  type = string
}

variable "project_number" {
  type = string
}

variable "region" {
  description = "Single-region user-managed replication in dev; prod adds a 2nd"
  type        = string
}

variable "secrets" {
  description = "secret_id -> { accessors = [IAM members] }"
  type = map(object({
    accessors = optional(list(string), [])
  }))
  default = {}
}

variable "rotation_topic_name" {
  description = "Pub/Sub topic for 90d rotation reminders; empty to disable"
  type        = string
  default     = ""
}

variable "rotation_period" {
  type    = string
  default = "7776000s"
}
