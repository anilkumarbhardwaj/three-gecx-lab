# ---------------------------------------------------------------------------
# 1-foundation — folders, environment projects, org-level guardrails.
# In 3IR most org policies are INHERITED from THREE; here you own the org,
# so you get to build them — the exact list from the design doc §3/§6.
# Runs as sa-tf-foundation (via WIF in GitHub Actions).
# ---------------------------------------------------------------------------

locals {
  env_folder = { dev = "nonprod", prod = "prod" }
}

# --- Environment folders ------------------------------------------------------

resource "google_folder" "env" {
  for_each     = toset(distinct(values(local.env_folder)))
  display_name = "fldr-gecx-${each.value}"
  parent       = var.gecx_folder_id
}

# --- Workload projects ---------------------------------------------------------

resource "google_project" "gecx" {
  for_each        = toset(var.environments)
  name            = "gecx-${each.value}"
  project_id      = "${var.prefix}-gecx-${each.value}"
  folder_id       = google_folder.env[local.env_folder[each.value]].name
  billing_account = var.billing_account_id
  deletion_policy = "DELETE" # lab only
  labels = {
    app = "gecx"
    env = each.value
  }
}


resource "google_project_service" "gecx" {
  for_each = { for pair in setproduct(var.environments, [
    "compute.googleapis.com",
    "iam.googleapis.com", ## For WIF to work, this must be enabled in the workload project.
    "dns.googleapis.com",
    "networkconnectivity.googleapis.com",
    "run.googleapis.com",
    "cloudkms.googleapis.com",
    "secretmanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "iamcredentials.googleapis.com",
  ]) : "${pair[0]}-${pair[1]}" => { env = pair[0], api = pair[1] } }

  project            = google_project.gecx[each.value.env].project_id
  service            = each.value.api
  disable_on_destroy = false
}

# --- Organisation policies (guardrails) ----------------------------------------
# Mirrors the 3IR inherited posture. Applied at ORG level here since you own it.

locals {
  boolean_policies = [
    "iam.disableServiceAccountKeyCreation",
    "iam.disableServiceAccountKeyUpload",
    "iam.automaticIamGrantsForDefaultServiceAccounts",
    "compute.skipDefaultNetworkCreation",
    "compute.requireOsLogin",
    "compute.disableSerialPortAccess",
    "storage.uniformBucketLevelAccess",
    "storage.publicAccessPrevention",
    "sql.restrictPublicIp",
  ]
}

resource "google_org_policy_policy" "boolean" {
  for_each = toset(local.boolean_policies)
  name     = "organizations/${var.org_id}/policies/${each.value}"
  parent   = "organizations/${var.org_id}"
  spec {
    rules { enforce = "TRUE" }
  }
}

# No external IPs on VMs anywhere
resource "google_org_policy_policy" "no_external_ip" {
  name   = "organizations/${var.org_id}/policies/compute.vmExternalIpAccess"
  parent = "organizations/${var.org_id}"
  spec {
    rules { deny_all = "TRUE" }
  }
}

# EU-only resource locations (Principle 6 / GDPR posture)
resource "google_org_policy_policy" "eu_only" {
  name   = "organizations/${var.org_id}/policies/gcp.resourceLocations"
  parent = "organizations/${var.org_id}"
  spec {
    rules {
      values {
        allowed_values = ["in:eu-locations"]
      }
    }
  }
}

# Domain-restricted sharing: only identities from YOUR Cloud Identity customer.
# Find your customer ID:  gcloud organizations describe <ORG_ID> --format='value(directoryCustomerId)'
# Commented out by default — enabling it while misconfigured can lock you out.
#
# resource "google_org_policy_policy" "domain_restricted" {
#   name   = "organizations/${var.org_id}/policies/iam.allowedPolicyMemberDomains"
#   parent = "organizations/${var.org_id}"
#   spec {
#     rules {
#       values {
#         allowed_values = ["C0xxxxxxx"]
#       }
#     }
#   }
# }

# --- Org-level log sink (mirrors THREE central logging, Principle 10) ----------

resource "google_logging_organization_sink" "central" {
  name             = "sk-org-central-audit"
  org_id           = var.org_id
  include_children = true
  destination      = "storage.googleapis.com/${google_storage_bucket.central_logs.name}"
  filter           = "logName:\"cloudaudit.googleapis.com\""
}

resource "google_storage_bucket" "central_logs" {
  project                     = var.cicd_project_id
  name                        = "${var.prefix}-gecx-central-audit-logs"
  location                    = "europe-west1"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  lifecycle_rule {
    condition { age = 30 } # lab: keep costs near zero
    action { type = "Delete" }
  }
}

resource "google_storage_bucket_iam_member" "sink_writer" {
  bucket = google_storage_bucket.central_logs.name
  role   = "roles/storage.objectCreator"
  member = google_logging_organization_sink.central.writer_identity
}
