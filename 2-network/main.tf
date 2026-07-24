# ---------------------------------------------------------------------------
# 2-network — VPC/subnets, Cloud Router+NAT, Cloud DNS, firewall policy,
# serverless VPC connector. Workbook sheets 04, 05, 07, 08, 09.
# Sheet 06 (NCC spoke): NOT REQUIRED — decision closed, SOA egresses via
# Cloud NAT static IP over the internet. Nothing deployed.
# Sheets 23/24 (Service Directory + internal ALB) live in 4-workload
# because their serverless NEGs/endpoint depend on the Cloud Run services.
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
  project_id   = data.terraform_remote_state.foundation.outputs.dev_project_id
  region_short = "euwe4"
  name_prefix  = "cxai-gecx-d"
}

# --- Sheet 04: VPC + subnets + reserved ILB IP -------------------------------

module "vpc" {
  source     = "../modules/vpc"
  project_id = local.project_id
  region     = var.region

  network_name = "${local.name_prefix}-vpc-${local.region_short}"

  workload_subnet = {
    name = "${local.name_prefix}-sub-${local.region_short}"
    cidr = "10.110.82.0/26"
  }
  connector_subnet = {
    name = "${local.name_prefix}-svpc-${local.region_short}"
    cidr = "10.110.82.64/28"
  }
  psc_subnet = {
    name = "${local.name_prefix}-psc-${local.region_short}"
    cidr = "10.110.82.80/28"
  }
  proxy_only_subnet = {
    name = "${local.name_prefix}-proxy-${local.region_short}"
    cidr = "10.110.82.128/26"
  }
  # Reserved for future growth within the /24: 10.110.82.96/27 + 10.110.82.192/26

  reserve_ilb_ip = true
  ilb_ip_name    = "${local.name_prefix}-ilbip-${local.region_short}"
}

# --- Sheet 05: Cloud Router + NAT (internet egress for SOA) ------------------
# COST: static IP + NAT bill hourly (~$0.045/hr + data). Gated behind
# enable_nat — apply while testing, destroy after (lab discipline).

module "cloud_nat" {
  source = "../modules/cloud-nat"
  count  = var.enable_nat ? 1 : 0

  project_id  = local.project_id
  region      = var.region
  network_id  = module.vpc.network_id
  router_name = "${local.name_prefix}-rtr-${local.region_short}"
  nat_name    = "${local.name_prefix}-nat-${local.region_short}"
  nat_ip_name = "${local.name_prefix}-natip-${local.region_short}"

  nat_subnet_ids = [
    module.vpc.workload_subnet_id,
    module.vpc.connector_subnet_id,
  ]
  min_ports_per_vm = 128 # tune after load test; watch nat_allocation_failed
}

# --- Sheet 07: Cloud DNS -----------------------------------------------------
# three.ie peering zone REMOVED (NCC decommissioned); SOA FQDN resolves via
# public DNS. googleapis/gcr/pkg.dev private zones replace hub peering.

module "dns" {
  source     = "../modules/dns"
  project_id = local.project_id
  network_id = module.vpc.network_id

  private_zone_name   = "dev-cxai-three-ie"
  private_zone_domain = "dev.cxai.three.ie"
  a_records = {
    "api.gecx" = module.vpc.ilb_frontend_ip # sheet 07 example record -> ILB IP
  }

  create_google_api_zones = true
  zone_name_prefix        = "${local.name_prefix}-pga"
}

# --- Sheet 08: network firewall policy (zero-trust) --------------------------

module "firewall_policy" {
  source     = "../modules/firewall-policy"
  project_id = local.project_id
  network_id = module.vpc.network_id

  policy_name       = "${local.name_prefix}-fwpol-${local.region_short}"
  cross_env_cidrs   = ["10.110.80.0/24", "10.110.81.0/24", "10.110.83.0/24"]
  soa_gateway_cidrs = var.soa_gateway_cidrs
  egress_secure_tag = "" # lab: rule 520 applies untagged; set tagValues/NNN in real env
}

# --- Sheet 09: Serverless VPC Access connector -------------------------------
# COST: e2-micro x min 2 instances bills hourly. Gated behind enable flag.

module "vpc_connector" {
  source = "../modules/vpc-connector"
  count  = var.enable_vpc_connector ? 1 : 0

  project_id     = local.project_id
  region         = var.region
  connector_name = "${local.name_prefix}-conn-${local.region_short}"
  subnet_name    = module.vpc.connector_subnet_name
  machine_type   = "e2-micro"
  min_instances  = 2
  max_instances  = 4 # dev; prod 10
}
