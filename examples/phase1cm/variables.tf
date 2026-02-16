#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# examples/phase1cm/variables.tf (GCP Version)
# Variables for Phase 1: Central Manager Deployment

# GCP Configuration
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

variable "network_name" {
  type        = string
  default     = "guardium-vpc"
  description = "Name of the VPC network"
}

variable "subnet_name" {
  type        = string
  default     = "guardium-subnet"
  description = "Name of the subnet"
}

variable "subnet_cidr" {
  type        = string
  default     = "10.0.0.0/24"
  description = "CIDR block for the subnet"
}

# Guardium Configuration
variable "guardium_aggregator_image_id" {
  type        = string
  description = "Guardium aggregator image ID (used for Central Manager)"
}

variable "guardium_machine_type" {
  type        = string
  description = "GCP machine type for Guardium instances"
  default     = "n2-highmem-4"
}

# Central Manager Configuration
variable "cm_config_json_path" {
  type        = string
  default     = "central_manager_config.json"
  description = "Path to Central Manager configuration JSON file"
}

variable "cm_instances_json_path" {
  type        = string
  default     = "central_manager_config.json"
  description = "Path to Central Manager configuration JSON file (legacy name)"
}

# SSH Configuration

# Resource flags
variable "use_existing_vpc" {
  type        = bool
  default     = true
  description = "Whether to use an existing VPC"
}

variable "use_existing_subnet" {
  type        = bool
  default     = true
  description = "Whether to use an existing subnet"
}

# Labels
variable "labels" {
  type = map(string)
  default = {
    project     = "guardium"
    environment = "production"
    managed_by  = "terraform"
  }
  description = "Labels to apply to all resources"
}

