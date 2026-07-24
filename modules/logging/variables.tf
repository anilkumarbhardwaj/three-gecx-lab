variable "project_id" {
  type = string
}

variable "log_bucket_location" {
  type = string
}

variable "retention_days" {
  type    = number
  default = 30
}

variable "sink_name" {
  type    = string
  default = "sk-central-audit"
}

variable "sink_destination" {
  description = "e.g. storage.googleapis.com/<bucket>; empty to skip"
  type        = string
  default     = ""
}

variable "data_access_services" {
  type = list(string)
  default = [
    "storage.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudkms.googleapis.com",
    "dialogflow.googleapis.com",
  ]
}

variable "log_metrics" {
  description = "metric name -> log filter"
  type        = map(string)
  default     = {}
}
