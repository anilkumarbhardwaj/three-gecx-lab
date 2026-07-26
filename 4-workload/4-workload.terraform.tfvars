# ============================================================
# 4-workload — GCS, Artifact Registry, Pub/Sub, Cloud Run,
# Service Directory, internal ALB (sheets 15,16,17,20,23,24)
# Fixed workbook names (in main.tf):
#   buckets  demo-lab-cxai-gecx-d-csb-euwe4-{transcripts,exports,artifacts}
#   AR repo  cxai-gecx-d-ar-euwe4 (DOCKER, immutable tags)
#   topics   conv-events-d / transcript-export-d (+ -dlq, 14d)
#   run      cxai-gecx-d-crun-{billing,orders,write-financial,voice}-euwe4
#   run SAs  sa-run-{tool}-d
#   SD       cxai-gecx-d-sdns-euwe4 / gecx-webhook
#   ALB      cxai-gecx-d-{fr,thp,um,bes-*,neg-*}-euwe4
#            host api.gecx.dev.cxai.three.ie (self-signed in lab)
# ============================================================

# state_bucket    = "demo-lab-cxai-gecx-tfstate"
# cicd_project_id = "demo-lab-cxai-gecx-cicd"
# prefix          = "demo-lab"
# region          = "europe-west4"

# # Must match 3-security tools (secret mounts reference sm-{tool}-dev)
# tools = ["billing", "orders", "write-financial"]

# # Sheet 16 — Artifact Registry writer
# deploy_sa_email = "sa-deploy-gecx-d@demo-lab-cxai-gecx-cicd.iam.gserviceaccount.com"

# # Sheet 15 — bucket objectViewer for developers; empty = skipped
# developers_group = ""
# # developers_group = "gcp-gecx-developers@yourdomain.com"

# # €€ gate — sheets 23/24 (ILB + Service Directory webhook path)
# enable_ilb = false

# # Local runs only (empty in CI)
# terraform_service_account = "sa-deploy-gecx-d@demo-lab-cxai-gecx-cicd.iam.gserviceaccount.com"
