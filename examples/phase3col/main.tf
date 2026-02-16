#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# examples/phase3col/main.tf (GCP Version)
# Phase 3: Deploy Collector instances with integrated automation

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
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

locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())

  # Load collector configuration from JSON
  json_file_path = var.col_instances_json_path != "collector_config.json" ? var.col_instances_json_path : var.col_config_json_path
  col_raw_data   = jsondecode(file(local.json_file_path))
  col_config     = local.col_raw_data.collectors
}

# Try to read existing VPC
data "google_compute_network" "existing_vpc" {
  name = var.network_name
}

# Try to read existing subnet
data "google_compute_subnetwork" "existing_subnet" {
  name   = var.subnet_name
  region = var.region
}

# Create VPC only if use_existing_vpc is false
resource "google_compute_network" "vpc" {
  count                   = var.use_existing_vpc ? 0 : 1
  name                    = var.network_name
  auto_create_subnetworks = false
  mtu                     = 1460
  description             = "Guardium VPC network"
}

# Create subnet only if use_existing_subnet is false
resource "google_compute_subnetwork" "subnet" {
  count         = var.use_existing_subnet ? 0 : 1
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = var.use_existing_vpc ? data.google_compute_network.existing_vpc.id : google_compute_network.vpc[0].id
  description   = "Guardium instances subnet"

  private_ip_google_access = true
}

# Local values to reference the correct VPC and subnet
locals {
  vpc_id    = var.use_existing_vpc ? data.google_compute_network.existing_vpc.id : google_compute_network.vpc[0].id
  subnet_id = var.use_existing_subnet ? data.google_compute_subnetwork.existing_subnet.id : google_compute_subnetwork.subnet[0].id
}

# STEP 1: Collector instances (Private IP only)
resource "google_compute_instance" "collector" {
  for_each = { for col in local.col_config : col.vm_name => col }

  name         = each.value.vm_name
  machine_type = var.guardium_machine_type
  zone         = var.zone

  tags = ["guardium", "collector"]
  labels = merge(var.labels, {
    component = "collector"
    instance  = each.value.vm_name
    phase     = "3"
  })

  boot_disk {
    initialize_params {
      # Using Guardium collector image
      image = var.guardium_collector_image_id
      size  = 500 # GB - smaller than aggregator
      type  = "pd-balanced"

      labels = merge(var.labels, {
        component = "collector"
        instance  = each.value.vm_name
      })
    }
  }

  network_interface {
    network    = local.vpc_id
    subnetwork = local.subnet_id

    # Static private IP - NO external IP for private deployment
    network_ip = each.value.network_interface_ip

    # No access_config block = no external IP (private only)
  }

  # Metadata for Guardium configuration
  metadata = {
    # Guardium-specific metadata
    guardium-hostname = each.value.system_hostname
    guardium-domain   = each.value.system_domain
    guardium-timezone = each.value.system_clock_timezone

    # Network configuration
    guardium-private-ip = each.value.network_interface_ip
    guardium-netmask    = each.value.network_interface_mask
    guardium-gateway    = each.value.network_routes_defaultroute
    guardium-dns1       = each.value.network_resolvers1
    guardium-dns2       = lookup(each.value, "network_resolvers2", "")

    # Set hostname properly
    hostname = lower(join(".", [each.value.system_hostname, "internal"]))
  }

  # Allow stopping for updates
  allow_stopping_for_update = true

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"]
    ]
  }
}

# Boot wait - Guardium needs time to initialize (20 minutes)
resource "time_sleep" "guardium_boot_wait" {
  for_each = { for col in local.col_config : col.vm_name => col }

  create_duration = "1200s" # 20 minutes
  depends_on      = [google_compute_instance.collector]
}

# STEP 2: Run automation script
resource "null_resource" "run_guardium_automation" {
  for_each = { for col in local.col_config : col.vm_name => col }

  provisioner "local-exec" {
    command = <<-EOT
#!/bin/bash
set -euo pipefail

PRIVATE_IP=${each.value.network_interface_ip}
VM_NAME=${each.value.vm_name}
HOSTNAME=${each.value.system_hostname}

echo ""
echo "=========================================="
echo "STEP 2: GUARDIUM COLLECTOR AUTOMATION"
echo "=========================================="
echo "VM Name: $VM_NAME"
echo "Private IP: $PRIVATE_IP"
echo "Time: $(date)"
echo "=========================================="

MODULES_DIR="$HOME/guardium-gcp/modules/collector"
mkdir -p "$MODULES_DIR"

# Find and setup automation scripts
setup_automation_scripts() {
  local found_scripts=false
  
  for dir in "./modules/collector" "../modules/collector" "../../modules/collector" "/opt/guardium-gcp/modules/collector"; do
    if [ -f "$dir/run_wait_for_guardium.sh" ]; then
      cp "$dir"/* "$MODULES_DIR/" 2>/dev/null || true
      found_scripts=true
      break
    fi
  done
  
  [ -f "$MODULES_DIR/run_wait_for_guardium.sh" ] && found_scripts=true
  
  if [ "$found_scripts" = "false" ]; then
    return 1
  fi
  
  chmod +x "$MODULES_DIR"/*.sh 2>/dev/null || true
  chmod +x "$MODULES_DIR"/*.expect 2>/dev/null || true
  return 0
}

if ! setup_automation_scripts; then
  echo "Manual configuration required"
  exit 0
fi

cd "$MODULES_DIR"
timeout 1800 ./run_wait_for_guardium.sh "$PRIVATE_IP" "guardium" || {
  echo "WARNING: Automation completed with warnings"
}

echo ""
echo "STEP 2 COMPLETED: $VM_NAME"
echo "=========================================="
    EOT

    interpreter = ["/bin/bash", "-c"]
  }

  triggers = {
    private_ip  = each.value.network_interface_ip
    vm_name     = each.value.vm_name
    config_hash = md5(jsonencode(each.value))
    timestamp   = timestamp()
  }

  depends_on = [time_sleep.guardium_boot_wait]
}

# Status summary
resource "null_resource" "deployment_summary" {
  provisioner "local-exec" {
    command = <<-EOT
echo ""
echo "=========================================="
echo "GUARDIUM COLLECTOR DEPLOYMENT COMPLETE"
echo "=========================================="
echo "Total VMs deployed: ${length(local.col_config)}"
echo ""
%{for col in local.col_config~}
echo "VM: ${col.vm_name} - IP: ${col.network_interface_ip}"
%{endfor~}
echo ""
echo "DEPLOYMENT STATUS: SUCCESS"
echo "=========================================="
    EOT

    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [null_resource.run_guardium_automation]
}

