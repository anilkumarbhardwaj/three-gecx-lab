variable "project_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "policy_name" {
  type = string
}

variable "cross_env_cidrs" {
  description = "Other environment /24s to deny (sheet 08 rule 400)"
  type        = list(string)
  default     = ["10.110.80.0/24", "10.110.81.0/24", "10.110.83.0/24"]
}

variable "soa_gateway_cidrs" {
  description = "3IR SOA public gateway IPs/CIDRs; empty = rule skipped until known"
  type        = list(string)
  default     = []
}

variable "egress_secure_tag" {
  description = "tagValues/NNN secure tag for external-api egress; empty = rule applies untagged (lab)"
  type        = string
  default     = ""
}
