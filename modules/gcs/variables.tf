variable "project_id" {
  type = string
}

variable "location" {
  type = string
}

variable "force_destroy" {
  type    = bool
  default = true # lab; false in real envs
}

variable "buckets" {
  description = "bucket name -> config. Names are GLOBAL — demo-lab prefix required."
  type = map(object({
    nearline_age_days = optional(number, 30)
    delete_age_days   = optional(number, 90)
    kms_key_id        = optional(string, "")
    object_admins     = optional(list(string), [])
    viewers           = optional(list(string), [])
  }))
  default = {}
}
