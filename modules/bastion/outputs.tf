#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/bastion/outputs.tf (GCP Version)

output "bastion_external_ip" {
  description = "External IP address of the bastion host"
  value       = local.bastion_ip_address
}

output "bastion_internal_ip" {
  description = "Internal IP address of the bastion host"
  value       = var.create_bastion ? google_compute_instance.bastion[0].network_interface[0].network_ip : var.bastion_private_ip
}

output "bastion_name" {
  description = "Name of the bastion host"
  value       = var.bastion_name
}

output "bastion_zone" {
  description = "Zone of the bastion host"
  value       = var.zone
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host (alias)"
  value       = local.bastion_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to bastion"
  value       = "ssh ${var.admin_username}@${local.bastion_ip_address}"
}

output "management_subnet_id" {
  description = "ID of the management subnet"
  value       = local.management_subnet_id
}
