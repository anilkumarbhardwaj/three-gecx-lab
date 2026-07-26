# ============================================================
# 3-security — KMS, secrets, logging, monitoring, DLP
# (sheets 10, 11, 12, 13, 14)
# Fixed workbook names (in main.tf):
#   keyring  cxai-gecx-d-kr-euwe4
#   keys     key-gcs-dev / key-bq-dev / key-secmgr-dev (90d rotation)
#   secrets  sm-{tool}-dev, sm-soa-oauth-dev,
#            sm-soa-mtls-cert-dev, sm-soa-mtls-key-dev
#   sink     sk-to-platform-logging  → central audit bucket
#   metrics  financial_tool_invocations, secret_access_unexpected_sa,
#            nat_translation_errors
# ============================================================

# state_bucket       = "demo-lab-cxai-gecx-tfstate"
# cicd_project_id    = "demo-lab-cxai-gecx-cicd"
# prefix             = "demo-lab"
# region             = "europe-west4"
# billing_account_id = "0196E3-CB7EFE-2CEC23"

# # Sheet 11 — drives secret names sm-billing-dev, sm-orders-dev,
# # sm-write-financial-dev (must match 4-workload)
# tools = ["billing", "orders", "write-financial"]

# # Email channel + €5 budget (sheet 13); empty = skipped
# alert_email = "you@example.com"

# # Sheet 10 — KMS admin group; empty = skipped in lab
# secops_group = ""
# # secops_group = "gcp-gecx-secops@yourdomain.com"

# # Sheet 14 — DLP off until you create the wrapped key out-of-band:
# #   openssl rand -base64 32 > /tmp/dlp.key
# #   gcloud kms encrypt --project demo-lab-cxai-gecx-dev \
# #     --location europe-west4 --keyring cxai-gecx-d-kr-euwe4 \
# #     --key key-secmgr-dev --plaintext-file /tmp/dlp.key \
# #     --ciphertext-file /tmp/dlp.key.enc
# #   base64 -w0 /tmp/dlp.key.enc   → paste below
# enable_dlp      = false
# dlp_wrapped_key = ""

# # Local runs only (empty in CI)
# terraform_service_account = "sa-deploy-gecx-d@demo-lab-cxai-gecx-cicd.iam.gserviceaccount.com"
