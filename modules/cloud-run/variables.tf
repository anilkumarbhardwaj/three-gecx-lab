variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "name_prefix" {
  description = "e.g. cxai-gecx-d — service becomes {prefix}-crun-{tool}"
  type        = string
}

variable "env_short" {
  description = "d / t / p — used in per-tool SA ids"
  type        = string
}

variable "connector_id" {
  description = "Serverless VPC connector id; empty = no VPC egress (lab cost saver)"
  type        = string
  default     = ""
}

variable "runtime_invoker_sa" {
  description = "Agent runtime SA email — the ONLY invoker besides the ILB path"
  type        = string
}

variable "tools" {
  description = "tool name -> adapter config"
  type = map(object({
    image         = optional(string, "us-docker.pkg.dev/cloudrun/container/hello") # placeholder until CI pushes real image
    min_instances = optional(number, 0)                                            # voice: 1
    max_instances = optional(number, 8)                                            # MANDATORY reviewed field
    concurrency   = optional(number, 40)                                           # voice: 20
    secret_mounts = optional(list(string), [])
  }))
  default = {}
}
