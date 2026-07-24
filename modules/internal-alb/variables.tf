variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "region_short" {
  description = "e.g. euwe4"
  type        = string
}

variable "name_prefix" {
  description = "e.g. cxai-gecx-d"
  type        = string
}

variable "network_id" {
  type = string
}

variable "workload_subnet_id" {
  type = string
}

variable "ilb_ip_id" {
  description = "Reserved static internal address id from vpc module"
  type        = string
}

variable "certificate_domain" {
  description = "e.g. api.gecx.dev.cxai.three.ie — CN/SAN must match sheet 07 DNS record"
  type        = string
}

variable "certificate_name" {
  type = string
}

variable "create_self_signed_cert" {
  type    = bool
  default = true
}

variable "ssl_certificate_ids" {
  description = "Used when create_self_signed_cert = false"
  type        = list(string)
  default     = []
}

variable "backends" {
  description = "tool -> { cloud_run_service, path }"
  type = map(object({
    cloud_run_service = string
    path              = string # e.g. /tools/billing/*
  }))
}

variable "default_backend" {
  description = "Key in var.backends used as the URL map default"
  type        = string
}
