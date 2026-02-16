#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# examples/phase0bastion/main.tf
# Phase 0: Deploy Bastion Host and Base Infrastructure (GCP Version)

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = file(var.credentials_file)
}

provider "google-beta" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = file(var.credentials_file)
}

# Phase 0: Create base networking infrastructure
module "networking" {
  source = "../../modules/networking"

  # Basic configuration
  region              = var.region
  network_name        = var.network_name
  network_description = "Guardium VPC network"

  # Subnets configuration
  subnet_name                 = var.subnet_name

  subnet_cidr                 = var.subnet_cidr
  guardium_subnet_description = "Guardium instances subnet"
  management_subnet_cidr      = var.management_subnet_cidr

  # Firewall configuration
  firewall_name = var.firewall_name

  # Private mode - restrict access
  private_mode = true

  # Create new resources (set to false if resources exist)
  create_vpc       = var.create_vpc
  create_subnet    = var.create_subnet
  create_nat       = var.create_nat
  create_firewalls = var.create_firewalls

  labels = var.labels
}

# Phase 0: Deploy bastion host
module "bastion" {
  source = "../../modules/bastion"

  # Resource configuration
  project_id = var.project_id
  region     = var.region
  zone       = var.zone

  # Network configuration
  network_name           = var.network_name
  subnet_name            = var.subnet_name
  management_subnet_name = var.management_subnet_name
  management_subnet_cidr = var.management_subnet_cidr
  guardium_subnet_cidr   = var.subnet_cidr

  # Bastion configuration
  bastion_name         = var.bastion_name
  bastion_machine_type = var.bastion_machine_type
  bastion_private_ip   = var.bastion_private_ip

  # Security configuration
  allowed_source_ips = var.allowed_source_ips

  # SSH configuration
  admin_username  = var.admin_username
  ssh_public_key  = var.ssh_public_key
  ssh_private_key = var.ssh_private_key

  # Resource creation flags
  create_management_subnet = var.create_management_subnet
  create_bastion           = var.create_bastion
  create_bastion_firewalls = var.create_bastion_firewalls
  create_bastion_ip        = var.create_bastion_ip

  labels = merge(var.labels, {
    phase     = "0-bastion"
    component = "bastion"
  })

  depends_on = [module.networking]
}
