terraform {
  required_version = ">= 1.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    prefix = "workload"
  }
}

provider "google" {
  impersonate_service_account = var.terraform_service_account != "" ? var.terraform_service_account : null
  user_project_override       = true
  billing_project             = var.cicd_project_id
}

provider "google-beta" {
  impersonate_service_account = var.terraform_service_account != "" ? var.terraform_service_account : null
  user_project_override       = true
  billing_project             = var.cicd_project_id
}
