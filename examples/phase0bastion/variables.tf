#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# examples/phase0bastion/variables.tf
# Variables for Phase 0: Bastion Host and Base Infrastructure (GCP Version)

# GCP Authentication & Project
variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "GCP region for deployment"
}

variable "zone" {
  type        = string
  default     = "us-central1-a"
  description = "GCP zone for deployment"
}

variable "credentials_file" {
  type        = string
  description = "Path to the GCP service account key file"
}

# Networking Configuration
variable "network_name" {
  type        = string
  default     = "guardium-vpc"
  description = "Name of the VPC network"
}

variable "subnet_name" {
  type        = string
  default     = "guardium-subnet"
  description = "Name of the Guardium subnet"
}

variable "subnet_cidr" {
  type        = string
  default     = "10.0.0.0/24"
  description = "CIDR block for the Guardium subnet"
}

variable "firewall_name" {
  type        = string
  default     = "guardium-firewall"
  description = "Name prefix for firewall rules"
}

# Bastion Configuration
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

variable "allowed_source_ips" {
  type        = list(string)
  description = "List of allowed source IPs for SSH access to bastion"
}

# SSH Configuration
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

# Labels (GCP equivalent of tags)
variable "labels" {
  type = map(string)
  default = {
    project     = "guardium"
    environment = "production"
    managed_by  = "terraform"
    mode        = "private"
  }
  description = "Labels to apply to all resources"
}

# Resource creation flags
variable "create_vpc" {
  type        = bool
  default     = true
  description = "Whether to create a new VPC or use existing"
}

variable "create_subnet" {
  type        = bool
  default     = true
  description = "Whether to create a new subnet or use existing"
}

variable "create_nat" {
  type        = bool
  default     = true
  description = "Whether to create Cloud NAT"
}

variable "create_management_subnet" {
  type        = bool
  default     = true
  description = "Whether to create the management subnet"
}

variable "create_firewalls" {
  type        = bool
  default     = true
  description = "Whether to create firewall rules (set to false if they already exist)"
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

