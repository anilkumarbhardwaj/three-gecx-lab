variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "connector_name" {
  description = "Max 25 chars, lowercase + hyphens"
  type        = string
}

variable "subnet_name" {
  description = "Dedicated /28 subnet, nothing else in it"
  type        = string
}

variable "machine_type" {
  type    = string
  default = "e2-micro"
}

variable "min_instances" {
  type    = number
  default = 2
}

variable "max_instances" {
  description = "Dev 4; prod 10"
  type        = number
  default     = 4
}
