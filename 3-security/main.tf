# ---------------------------------------------------------------------------
# 3-security — KMS, Secret Manager, logging & sinks, monitoring & alerting,
# DLP. Workbook sheets 10, 11, 12, 13, 14.
# Runs as sa-deploy-gecx-d via GitLab WIF.
# ---------------------------------------------------------------------------

data "terraform_remote_state" "foundation" {
  backend = "gcs"
  config = {
    bucket = var.state_bucket
    prefix = "foundation"
  }
}

locals {
  project_id     = data.terraform_remote_state.foundation.outputs.dev_project_id
  project_number = data.terraform_remote_state.foundation.outputs.dev_project_number
  region_short   = "euwe4"
  name_prefix    = "cxai-gecx-d"
}

# --- Sheet 10: Cloud KMS parity keyring --------------------------------------
# encrypterDecrypter -> service agents only; no human ever encrypts/decrypts.
# ~$0.06/key/month — three keys stays in pennies.

module "kms" {
  source     = "../modules/kms"
  project_id = local.project_id
  region     = var.region

  keyring_name = "${local.name_prefix}-kr-${local.region_short}"
  key_names    = ["key-gcs-dev", "key-bq-dev", "key-secmgr-dev"]

  # rotation 90d, destroy_scheduled_duration 30d (module defaults)
  key_encrypters = {
    "key-gcs-dev"    = ["serviceAccount:service-${local.project_number}@gs-project-accounts.iam.gserviceaccount.com"]
    "key-bq-dev"     = ["serviceAccount:bq-${local.project_number}@bigquery-encryption.iam.gserviceaccount.com"]
    "key-secmgr-dev" = ["serviceAccount:service-${local.project_number}@gcp-sa-secretmanager.iam.gserviceaccount.com"]
  }
  admin_group = var.secops_group # empty = skipped in lab
}

# --- Sheet 11: Secret Manager shells -----------------------------------------
# Values NEVER in terraform state — add versions manually or via CI.

module "secrets" {
  source         = "../modules/secrets"
  project_id     = local.project_id
  project_number = local.project_number
  region         = var.region # user-managed single region (dev); prod adds euwe1

  secrets = merge(
    # sm-{tool}-dev — per-tool SOA/API credentials
    { for tool in var.tools : "sm-${tool}-dev" => { accessors = [] } },
    {
      "sm-soa-oauth-dev"     = { accessors = [] } # OAuth2 client id/secret, SOA public gateway
      "sm-soa-mtls-cert-dev" = { accessors = [] } # mTLS client certificate
      "sm-soa-mtls-key-dev"  = { accessors = [] } # mTLS private key — rotation runbook required
    }
  )

  rotation_topic_name = "secret-rotation-reminders-d"
}

# --- Sheet 12: logging, sinks, audit config, log metrics ---------------------

module "logging" {
  source     = "../modules/logging"
  project_id = local.project_id

  log_bucket_location = var.region
  retention_days      = 30 # dev; prod 400d locked

  # Lab substitute for the platform logging project: central audit bucket
  # created by 1-foundation in the cicd project.
  sink_name        = "sk-to-platform-logging"
  sink_destination = "storage.googleapis.com/${var.prefix}-cxai-gecx-central-audit-logs"

  data_access_services = [
    "storage.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudkms.googleapis.com",
    "dialogflow.googleapis.com",
  ]

  log_metrics = {
    financial_tool_invocations = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${local.name_prefix}-crun-write-financial\" AND httpRequest.requestMethod=\"POST\""
    secret_access_unexpected_sa = "protoPayload.serviceName=\"secretmanager.googleapis.com\" AND protoPayload.methodName=\"google.cloud.secretmanager.v1.SecretManagerService.AccessSecretVersion\""
    nat_translation_errors      = "resource.type=\"nat_gateway\" AND jsonPayload.allocation_status=\"DROPPED\""
  }
}

# Sink writer must be able to write into the central bucket
resource "google_storage_bucket_iam_member" "sink_writer" {
  bucket = "${var.prefix}-cxai-gecx-central-audit-logs"
  role   = "roles/storage.objectCreator"
  member = module.logging.sink_writer_identity
}

# --- Sheet 13: monitoring, alerting, budget ----------------------------------

module "monitoring" {
  source         = "../modules/monitoring"
  project_id     = local.project_id
  project_number = local.project_number

  billing_account_id      = var.billing_account_id
  alert_email             = var.alert_email
  run_5xx_threshold       = 0.05 # dev; prod 0.01
  connector_max_instances = 4

  create_budget   = var.alert_email != "" ? true : false
  budget_amount   = 5
  budget_currency = "EUR"
}

# --- Sheet 14: DLP templates -------------------------------------------------
# Needs a KMS-wrapped data key generated out-of-band (never in state):
#   openssl rand 32 | gcloud kms encrypt --key=key-secmgr-dev ... | base64
# Disabled until enable_dlp = true and dlp_wrapped_key is supplied
# (count can't reference the sensitive key directly).

module "dlp" {
  source = "../modules/dlp"
  count  = var.enable_dlp ? 1 : 0

  project_id = local.project_id
  region     = var.region

  inspect_template_name    = "${local.name_prefix}-inspect"
  deidentify_template_name = "${local.name_prefix}-deidentify"
  kms_key_id               = module.kms.key_ids["key-secmgr-dev"]
  wrapped_key              = var.dlp_wrapped_key
}
