#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/collector/variables.tf (GCP Version)

# GCP Configuration
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

# Network configuration
variable "network_name" {
  type        = string
  description = "Name of the VPC network"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet"
}

# VM configuration
variable "vm_name" {
  type        = string
  description = "Name of the virtual machine"
}

variable "machine_type" {
  type        = string
  description = "GCP machine type"
  default     = "n2-highmem-4" # 4 vCPUs, 32 GB memory
}

variable "guardium_image_id" {
  type        = string
  description = "Guardium collector image ID"
}

# Network configuration
variable "private_ip" {
  type        = string
  description = "Static private IP address"
}

variable "host_name" {
  type        = string
  description = "System hostname"
}

variable "domain_name" {
  type        = string
  description = "System domain name"
}

variable "subnet_mask" {
  type        = string
  description = "Subnet mask (CIDR or dotted decimal)"
}

variable "default_gateway" {
  type        = string
  description = "Default gateway IP address"
}

variable "resolver_1" {
  type        = string
  description = "Primary DNS resolver"
}

variable "resolver_2" {
  type        = string
  default     = null
  description = "Secondary DNS resolver (optional)"
}

variable "timezone" {
  type        = string
  default     = "America/New_York"
  description = "System timezone"
}

# Authentication
variable "guardium_default_pw" {
  type        = string
#  sensitive   = true
  description = "Initial Guardium CLI password"
  default     = "guardium"
}

variable "guardium_final_pw" {
  type        = string
#  sensitive   = true
  description = "Final password after configuration"
}

variable "guardium_shared_secret" {
  type        = string
#  sensitive   = true
  description = "Guardium Shared Secret Password"
}

variable "guardium_license_key" {
  type        = string
#  sensitive   = true
  description = "Guardium License Key"
}

variable "guardium_central_manager_ip" {
  type        = string
  description = "Guardium Central Manager IP"
}

# Phase control
variable "phase" {
  type        = string
  default     = "3"
  description = "Deployment phase"
}

# Labels (GCP equivalent of tags)
variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to all resources"
}

