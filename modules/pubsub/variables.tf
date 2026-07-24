variable "project_id" {
  type = string
}

variable "project_number" {
  type = string
}

variable "topics" {
  description = "topic name -> { retention, avro_schema (empty = no schema) }"
  type = map(object({
    retention   = optional(string, "604800s") # 7d
    avro_schema = optional(string, "")
  }))
  default = {}
}
