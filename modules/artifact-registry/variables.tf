variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "repository_id" {
  type = string
}

variable "writers" {
  description = "IAM members, e.g. deploy SA via WIF"
  type        = list(string)
  default     = []
}

variable "readers" {
  description = "IAM members, e.g. Cloud Run service agent"
  type        = list(string)
  default     = []
}
