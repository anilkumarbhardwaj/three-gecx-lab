terraform {
  required_version = ">= 1.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
  backend "gcs" {
    prefix = "network"
  }
}

provider "google" {
  impersonate_service_account = var.terraform_service_account != "" ? var.terraform_service_account : null
  user_project_override       = true
  billing_project             = var.cicd_project_id
}
