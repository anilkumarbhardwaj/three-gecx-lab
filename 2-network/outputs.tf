output "network_id" {
  value = module.vpc.network_id
}

output "network_name" {
  value = module.vpc.network_name
}

output "workload_subnet_id" {
  value = module.vpc.workload_subnet_id
}

output "ilb_frontend_ip" {
  value = module.vpc.ilb_frontend_ip
}

output "ilb_frontend_ip_id" {
  value = module.vpc.ilb_frontend_ip_id
}

output "nat_static_ips" {
  description = "Give these to 3IR for the SOA gateway allowlist"
  value       = var.enable_nat ? module.cloud_nat[0].nat_static_ips : []
}

output "vpc_connector_id" {
  value = var.enable_vpc_connector ? module.vpc_connector[0].connector_id : ""
}
