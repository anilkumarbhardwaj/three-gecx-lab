variable "project_id" {
  type = string
}

variable "project_number" {
  type = string
}

variable "region" {
  type = string
}

variable "namespace_id" {
  type = string
}

variable "service_id" {
  type    = string
  default = "gecx-webhook"
}

variable "ilb_ip" {
  description = "Reserved static internal ILB frontend IP (sheet 04)"
  type        = string
}

variable "network_name" {
  type = string
}
