variable "project_id" {
  type = string
}

variable "project_number" {
  type = string
}

variable "billing_account_id" {
  type = string
}

variable "alert_email" {
  type    = string
  default = ""
}

variable "run_5xx_threshold" {
  description = "0.05 dev; 0.01 prod"
  type        = number
  default     = 0.05
}

variable "connector_max_instances" {
  type    = number
  default = 4
}

variable "create_budget" {
  type    = bool
  default = true
}

variable "budget_amount" {
  type    = number
  default = 5
}

variable "budget_currency" {
  type    = string
  default = "EUR"
}
