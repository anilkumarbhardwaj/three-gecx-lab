variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "network_name" {
  type = string
}

variable "workload_subnet" {
  type = object({ name = string, cidr = string })
}

variable "connector_subnet" {
  type = object({ name = string, cidr = string })
}

variable "psc_subnet" {
  type    = object({ name = string, cidr = string })
  default = null
}

variable "proxy_only_subnet" {
  type    = object({ name = string, cidr = string })
  default = null
}

variable "reserve_ilb_ip" {
  type    = bool
  default = true
}

variable "ilb_ip_name" {
  type    = string
  default = ""
}
