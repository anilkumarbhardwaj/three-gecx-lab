terraform {
  required_version = ">= 1.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
  # Step 1: leave backend commented out, apply with local state.
  # Step 2: after the bucket exists, uncomment and run:
  # #   terraform init -migrate-state
  #
  backend "gcs" {
    bucket = "three01-gecx-tfstate" # value of output `state_bucket`
    prefix = "bootstrap"
  }
}

provider "google" {
  # Uses your Application Default Credentials:
  #   gcloud auth application-default login
  user_project_override = true
  billing_project       = var.quota_project_id != "" ? var.quota_project_id : null
}
