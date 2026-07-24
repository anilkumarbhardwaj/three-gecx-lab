variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "network_id" {
  type = string
}

variable "router_name" {
  type = string
}

variable "nat_name" {
  type = string
}

variable "nat_ip_name" {
  type = string
}

variable "nat_ip_count" {
  description = "1 to start; add a 2nd before port pressure (sheet 05)"
  type        = number
  default     = 1
}

variable "nat_subnet_ids" {
  description = "Self-links of subnets allowed to NAT (workload /26 + connector /28 only)"
  type        = list(string)
}

variable "min_ports_per_vm" {
  type    = number
  default = 128
}
