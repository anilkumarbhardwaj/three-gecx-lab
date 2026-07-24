# ---------------------------------------------------------------------------
# 4-workload — GCS buckets, Artifact Registry, Pub/Sub, Cloud Run tool
# adapters, Service Directory + Private Network Access, internal ALB.
# Workbook sheets 15, 16, 17, 20, 23, 24.
# Sheets 23/24 are 2-network in the workbook but live here because the
# serverless NEGs / SD endpoint depend on the Cloud Run services.
# Sheet 18 (BigQuery) + 19 (Dataplex): Not Required anymore — modules/bigquery
# retained but not wired. Sheet 21 (Functions gen2) is deployed by the app
# pipeline (needs source); its trigger topics + SAs are covered here/sheet 03.
# Runs as sa-deploy-gecx-d via GitLab WIF.
# ---------------------------------------------------------------------------

data "terraform_remote_state" "foundation" {
  backend = "gcs"
  config = {
    bucket = var.state_bucket
    prefix = "foundation"
  }
}

data "terraform_remote_state" "network" {
  backend = "gcs"
  config = {
    bucket = var.state_bucket
    prefix = "network"
  }
}

locals {
  project_id     = data.terraform_remote_state.foundation.outputs.dev_project_id
  project_number = data.terraform_remote_state.foundation.outputs.dev_project_number
  runtime_sa     = data.terraform_remote_state.foundation.outputs.runtime_invoker_sa
  net            = data.terraform_remote_state.network.outputs
  region_short   = "euwe4"
  name_prefix    = "cxai-gecx-d"
}

# --- Sheet 15: Cloud Storage -------------------------------------------------
# Bucket names are GLOBAL -> demo-lab prefix.

module "gcs" {
  source     = "../modules/gcs"
  project_id = local.project_id
  location   = var.region

  buckets = {
    "${var.prefix}-${local.name_prefix}-csb-${local.region_short}-transcripts" = {
      nearline_age_days = 30
      delete_age_days   = 90 # dev lifecycle per sheet 15
      # kms_key_id: Google-managed in dev; CMEK (key-gcs-dev) in prod/test
      viewers = var.developers_group != "" ? ["group:${var.developers_group}"] : []
    }
    "${var.prefix}-${local.name_prefix}-csb-${local.region_short}-exports" = {
      nearline_age_days = 30
      delete_age_days   = 90
    }
    "${var.prefix}-${local.name_prefix}-csb-${local.region_short}-artifacts" = {
      nearline_age_days = 30
      delete_age_days   = 90
    }
  }
}

# --- Sheet 16: Artifact Registry ---------------------------------------------
# Shared remotes / virtual repos / golden bases live in cxai-shared-p in 3IR
# — out of lab scope. Standard docker repo only.

module "artifact_registry" {
  source     = "../modules/artifact-registry"
  project_id = local.project_id
  region     = var.region

  repository_id = "${local.name_prefix}-ar-${local.region_short}"
  writers       = ["serviceAccount:${var.deploy_sa_email}"]
  readers = [
    "serviceAccount:service-${local.project_number}@serverless-robot-prod.iam.gserviceaccount.com" # Cloud Run service agent
  ]
}

# --- Sheet 17: Pub/Sub topics + DLQs -----------------------------------------

module "pubsub" {
  source         = "../modules/pubsub"
  project_id     = local.project_id
  project_number = local.project_number

  topics = {
    "conv-events-d"       = { retention = "604800s" } # conversation lifecycle; attach Avro schema when contract lands
    "transcript-export-d" = { retention = "604800s" } # export pipeline trigger
  }
}

# --- Sheet 20: Cloud Run tool adapters ---------------------------------------
# Terraform owns the shell; pipeline owns image/revisions.

module "cloud_run" {
  source     = "../modules/cloud-run"
  project_id = local.project_id
  region     = var.region

  name_prefix        = local.name_prefix
  env_short          = "d"
  connector_id       = local.net.vpc_connector_id # empty if connector disabled (lab cost saver)
  runtime_invoker_sa = local.runtime_sa

  tools = merge(
    { for tool in var.tools : tool => {
      secret_mounts = ["sm-${tool}-dev", "sm-soa-mtls-cert-dev", "sm-soa-mtls-key-dev"]
    } },
    {
      voice = {
        min_instances = 1  # voice keeps a warm instance (sheet 20)
        concurrency   = 20 # http2
        secret_mounts = []
      }
    }
  )
}

# --- Sheets 23 + 24: Service Directory + internal ALB ------------------------
# COST/complexity gate: enable_ilb builds the full private webhook path
# (proxy-only subnet already exists from 2-network).

module "internal_alb" {
  source = "../modules/internal-alb"
  count  = var.enable_ilb ? 1 : 0

  project_id   = local.project_id
  region       = var.region
  region_short = local.region_short
  name_prefix  = local.name_prefix

  network_id         = local.net.network_id
  workload_subnet_id = local.net.workload_subnet_id
  ilb_ip_id          = local.net.ilb_frontend_ip_id

  certificate_domain      = "api.gecx.dev.cxai.three.ie" # must match sheet 07 DNS record
  certificate_name        = "${local.name_prefix}-cert-${local.region_short}"
  create_self_signed_cert = true # lab; Three internal CA / ACME in real env

  backends = merge(
    { for tool in var.tools : tool => {
      cloud_run_service = module.cloud_run.service_names[tool]
      path              = "/tools/${tool}/*"
    } },
    {
      voice = {
        cloud_run_service = module.cloud_run.service_names["voice"]
        path              = "/voice/*"
      }
    }
  )
  default_backend = var.tools[0]
}

module "service_directory" {
  source = "../modules/service-directory"
  count  = var.enable_ilb ? 1 : 0

  project_id     = local.project_id
  project_number = local.project_number
  region         = var.region

  namespace_id = "${local.name_prefix}-sdns-${local.region_short}"
  service_id   = "gecx-webhook"
  ilb_ip       = local.net.ilb_frontend_ip
  network_name = local.net.network_name
}
