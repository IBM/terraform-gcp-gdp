# modules/networking/outputs.tf (GCP Version)

output "network_id" {
  description = "ID of the VPC network"
  value       = local.vpc_id
}

output "network_name" {
  description = "Name of the VPC network"
  value       = local.vpc_name
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = local.vpc_self_link
}

output "subnet_id" {
  description = "ID of the Guardium subnet"
  value       = local.subnet_id
}

output "subnet_name" {
  description = "Name of the Guardium subnet"
  value       = local.subnet_name
}

output "subnet_self_link" {
  description = "Self link of the Guardium subnet"
  value       = local.subnet_self_link
}

output "router_name" {
  description = "Name of the Cloud Router"
  value       = var.create_nat ? google_compute_router.router[0].name : null
}

output "nat_name" {
  description = "Name of the Cloud NAT"
  value       = var.create_nat ? google_compute_router_nat.nat[0].name : null
}

