terraform {
  required_version = ">= 1.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
  backend "gcs" {
    # bucket is passed at init time so the repo stays generic:
    #   terraform init -backend-config="bucket=<PREFIX>-gecx-tfstate"
    prefix = "foundation"
  }
}

# In CI this provider authenticates via WIF as sa-tf-foundation.
# Locally you can test with:
#   gcloud auth application-default login
# and impersonation:
provider "google" {
  impersonate_service_account = var.terraform_service_account != "" ? var.terraform_service_account : null
  user_project_override       = true
  billing_project             = var.cicd_project_id
}
