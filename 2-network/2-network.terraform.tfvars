# ============================================================
# 2-network — VPC, NAT, DNS, firewall, connector
# (sheets 04, 05, 07, 08, 09)
# Fixed workbook names (in main.tf, not variables):
#   VPC        cxai-gecx-d-vpc-euwe4        10.110.82.0/24
#   subnets    …-snet-workload-euwe4  10.110.82.0/26
#              …-snet-conn-euwe4      10.110.82.64/28
#              …-snet-psc-euwe4       10.110.82.80/28
#              …-snet-proxy-euwe4     10.110.82.128/26
#   ILB IP     cxai-gecx-d-ilbip-euwe4
#   router/NAT cxai-gecx-d-rtr-euwe4 / cxai-gecx-d-nat-euwe4
#   DNS        dev.cxai.three.ie + PGA zones (cxai-gecx-d-pga-*)
#   fw policy  cxai-gecx-d-fwpol-euwe4 (rules 100→65534)
#   connector  cxai-gecx-d-conn-euwe4
# ============================================================

# state_bucket    = "demo-lab-cxai-gecx-tfstate"
# cicd_project_id = "demo-lab-cxai-gecx-cicd"
# region          = "europe-west4"

# # €€ gates — flip on only while testing (sheets 05, 09)
# enable_nat           = false
# enable_vpc_connector = false

# # Sheet 08 rule 500: 3IR SOA public gateway CIDRs — empty until confirmed
# soa_gateway_cidrs = []
# # soa_gateway_cidrs = ["203.0.113.10/32"]

# # Local runs only (empty in CI)
# terraform_service_account = "sa-deploy-gecx-d@demo-lab-cxai-gecx-cicd.iam.gserviceaccount.com"
