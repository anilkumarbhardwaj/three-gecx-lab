# ---------------------------------------------------------------------------
# 0-bootstrap — run ONCE locally as a human org admin.
# Creates: fldr-gecx, the CI/CD project, TF state bucket, per-stage
# Terraform service accounts, and Workload Identity Federation for
# GitHub Actions (no service account keys, ever — mirrors 3IR).
# ---------------------------------------------------------------------------

locals {
  cicd_project_id = "${var.prefix}-gecx-cicd"
  state_bucket    = "${var.prefix}-gecx-tfstate"
  wif_repo        = var.github_repository
}

# --- Hierarchy ---------------------------------------------------------------

resource "google_folder" "gecx" {
  display_name = "fldr-gecx"
  parent       = "organizations/${var.org_id}"
}

# --- CI/CD project -----------------------------------------------------------

resource "google_project" "cicd" {
  name            = "gecx-cicd"
  project_id      = local.cicd_project_id
  folder_id       = google_folder.gecx.name
  billing_account = var.billing_account_id
  deletion_policy = "DELETE" # lab only; use PREVENT in real setups
  labels = {
    app = "gecx"
    env = "shared"
  }
}

resource "google_project_service" "cicd" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "serviceusage.googleapis.com",
    "orgpolicy.googleapis.com",
    "storage.googleapis.com",
  ])
  project            = google_project.cicd.project_id
  service            = each.value
  disable_on_destroy = false
}

# --- Terraform state bucket --------------------------------------------------

resource "google_storage_bucket" "tfstate" {
  project                     = google_project.cicd.project_id
  name                        = local.state_bucket
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  versioning { enabled = true }
  depends_on = [google_project_service.cicd]
}

# --- Per-stage Terraform service accounts ------------------------------------
# 3IR would split further (org / net / per-env). Two are enough for the lab
# while keeping the "stage-scoped SA" pattern intact.

resource "google_service_account" "tf_foundation" {
  project      = google_project.cicd.project_id
  account_id   = "sa-tf-foundation"
  display_name = "Terraform - foundation stage (folders, projects, org policies)"
}

resource "google_service_account" "tf_workloads" {
  project      = google_project.cicd.project_id
  account_id   = "sa-tf-workloads"
  display_name = "Terraform - network/security/workload stages"
}

# Foundation SA: org-level rights it needs to build the foundation
resource "google_organization_iam_member" "tf_foundation" {
  for_each = toset([
    "roles/resourcemanager.folderAdmin",
    "roles/resourcemanager.projectCreator",
    "roles/orgpolicy.policyAdmin",
    "roles/logging.configWriter",
  ])
  org_id = var.org_id
  role   = each.value
  member = "serviceAccount:${google_service_account.tf_foundation.email}"
}

resource "google_billing_account_iam_member" "tf_foundation_billing" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.tf_foundation.email}"
}

# Workloads SA: scoped to the GECX folder only (never org-wide)
resource "google_folder_iam_member" "tf_workloads" {
  for_each = toset([
    "roles/editor", # lab shortcut; tighten per-service in real setup
    "roles/resourcemanager.projectIamAdmin",
    "roles/compute.xpnAdmin",
  ])
  folder = google_folder.gecx.name
  role   = each.value
  member = "serviceAccount:${google_service_account.tf_workloads.email}"
}

# Both SAs read/write state
resource "google_storage_bucket_iam_member" "state_access" {
  for_each = {
    foundation = google_service_account.tf_foundation.email
    workloads  = google_service_account.tf_workloads.email
  }
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${each.value}"
}

# --- Workload Identity Federation for GitHub Actions -------------------------

resource "google_iam_workload_identity_pool" "github" {
  project                   = google_project.cicd.project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = google_project.cicd.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Only THIS repo can ever exchange tokens
  attribute_condition = "assertion.repository == \"${local.wif_repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Let workflows from the repo impersonate the stage SAs
resource "google_service_account_iam_member" "wif" {
  for_each = {
    foundation = google_service_account.tf_foundation.name
    workloads  = google_service_account.tf_workloads.name
  }
  service_account_id = each.value
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${local.wif_repo}"
}

# --- Workload Identity Federation for GitLab CI/CD ---------------------------

resource "google_iam_workload_identity_pool" "gitlab" {
  project                   = google_project.cicd.project_id
  workload_identity_pool_id = "gitlab-pool"
  display_name              = "GitLab CI/CD"
}

resource "google_iam_workload_identity_pool_provider" "gitlab" {
  project                            = google_project.cicd.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.gitlab.workload_identity_pool_id
  workload_identity_pool_provider_id = "gitlab-oidc"
  display_name                       = "GitLab OIDC"

  attribute_mapping = {
    "google.subject"         = "assertion.sub"
    "attribute.project_path" = "assertion.project_path"
    "attribute.ref"          = "assertion.ref"
    "attribute.ref_type"     = "assertion.ref_type"
  }

  # Only THIS project can ever exchange tokens
  attribute_condition = "assertion.project_path == \"${var.gitlab_project_path}\""

  oidc {
    issuer_uri = var.gitlab_url
  }
}

# Let GitLab CI/CD jobs from the project impersonate the stage SAs
resource "google_service_account_iam_member" "wif_gitlab" {
  for_each = {
    foundation = google_service_account.tf_foundation.name
    workloads  = google_service_account.tf_workloads.name
  }
  service_account_id = each.value
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gitlab.name}/attribute.project_path/${var.gitlab_project_path}"
}
