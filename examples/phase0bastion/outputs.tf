#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# examples/phase0bastion/outputs.tf

output "bastion_external_ip" {
  description = "External IP address of the bastion host"
  value       = module.bastion.bastion_external_ip
}

output "bastion_internal_ip" {
  description = "Internal IP address of the bastion host"
  value       = module.bastion.bastion_internal_ip
}

output "bastion_name" {
  description = "Name of the bastion host"
  value       = module.bastion.bastion_name
}

output "bastion_zone" {
  description = "Zone of the bastion host"
  value       = module.bastion.bastion_zone
}

output "ssh_command" {
  description = "SSH command to connect to bastion"
  value       = module.bastion.ssh_command
}

output "network_name" {
  description = "Name of the VPC network"
  value       = module.networking.network_name
}

output "subnet_name" {
  description = "Name of the Guardium subnet"
  value       = module.networking.subnet_name
}

