# Module: vpc-connector — Serverless VPC Access (workbook sheet 09)
# All Cloud Run / Functions egress routes VPC -> firewall -> NAT.
# NOTE: connector instances bill hourly (e2-micro x min_instances) — gate
# behind enable flag in the lab and destroy between sessions.

resource "google_vpc_access_connector" "this" {
  project = var.project_id
  name    = var.connector_name
  region  = var.region

  subnet {
    name = var.subnet_name
  }

  machine_type  = var.machine_type
  min_instances = var.min_instances
  max_instances = var.max_instances
}
