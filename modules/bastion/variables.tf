#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/bastion/variables.tf (GCP Version)

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "zone" {
  type        = string
  description = "GCP zone"
}

variable "network_name" {
  type        = string
  description = "Name of the VPC network"
}

variable "subnet_name" {
  type        = string
  description = "Name of the Guardium subnet"
}

variable "management_subnet_name" {
  type        = string
  default     = "management-subnet"
  description = "Name of the management subnet"
}

variable "management_subnet_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "CIDR block for the management subnet"
}

variable "guardium_subnet_cidr" {
  type        = string
  default     = "10.0.0.0/24"
  description = "CIDR block for the Guardium subnet"
}

variable "create_management_subnet" {
  type        = bool
  default     = true
  description = "Whether to create a new management subnet or use existing"
}

variable "bastion_name" {
  type        = string
  default     = "guardium-bastion"
  description = "Name of the bastion host"
}

variable "bastion_machine_type" {
  type        = string
  default     = "e2-standard-2"
  description = "GCP machine type for bastion host"
}

variable "bastion_private_ip" {
  type        = string
  default     = "10.0.1.10"
  description = "Static private IP for bastion host"
}

variable "allowed_source_ips" {
  type        = list(string)
  description = "List of allowed source IPs for SSH access to bastion"
}

variable "admin_username" {
  type        = string
  default     = "gcpuser"
  description = "Admin username for the bastion host"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for bastion host access"
}

variable "ssh_private_key" {
  type        = string
  sensitive   = true
  description = "SSH private key for bastion host setup"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to all resources"
}

variable "create_bastion" {
  type        = bool
  default     = true
  description = "Whether to create the bastion instance (set to false if it already exists)"
}

variable "create_bastion_firewalls" {
  type        = bool
  default     = true
  description = "Whether to create bastion firewall rules (set to false if they already exist)"
}

variable "create_bastion_ip" {
  type        = bool
  default     = true
  description = "Whether to create the bastion external IP (set to false if it already exists)"
}

