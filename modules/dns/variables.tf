variable "project_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "private_zone_name" {
  description = "Zone resource name, e.g. dev-cxai-three-ie"
  type        = string
}

variable "private_zone_domain" {
  description = "e.g. dev.cxai.three.ie (no trailing dot)"
  type        = string
}

variable "a_records" {
  description = "host (relative to zone) -> IP, e.g. { \"api.gecx\" = \"10.110.82.5\" }"
  type        = map(string)
  default     = {}
}

variable "create_google_api_zones" {
  type    = bool
  default = true
}

variable "zone_name_prefix" {
  type    = string
  default = "pga"
}
