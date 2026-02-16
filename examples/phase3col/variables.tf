#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# examples/phase3col/variables.tf (GCP Version)

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "GCP region"
}

variable "zone" {
  type        = string
  default     = "us-central1-a"
  description = "GCP zone"
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

variable "guardium_collector_image_id" {
  type        = string
  description = "Guardium collector image ID"
}

variable "guardium_machine_type" {
  type        = string
  default     = "n2-highmem-4"
  description = "GCP machine type"
}

variable "col_config_json_path" {
  type        = string
  default     = "collector_config.json"
  description = "Path to collector configuration JSON"
}

variable "col_instances_json_path" {
  type        = string
  default     = "collector_config.json"
  description = "Path to collector configuration JSON (legacy)"
}


variable "use_existing_vpc" {
  type        = bool
  default     = true
  description = "Use existing VPC"
}

variable "use_existing_subnet" {
  type        = bool
  default     = true
  description = "Use existing subnet"
}

variable "labels" {
  type = map(string)
  default = {
    project     = "guardium"
    environment = "production"
    managed_by  = "terraform"
  }
  description = "Labels"
}

