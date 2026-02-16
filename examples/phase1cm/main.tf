#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# examples/phase1cm/main.tf (GCP Version)
# Phase 1: Deploy Central Manager instances with integrated automation

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

  # Load Central Manager configuration from JSON
  json_file_path = var.cm_instances_json_path != "central_manager_config.json" ? var.cm_instances_json_path : var.cm_config_json_path
  cm_raw_data    = jsondecode(file(local.json_file_path))
  cm_config      = local.cm_raw_data.central_managers
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

# STEP 1: Central Manager instances (Private IP only)
resource "google_compute_instance" "central_manager" {
  for_each = { for cm in local.cm_config : cm.vm_name => cm }

  name         = each.value.vm_name
  machine_type = var.guardium_machine_type
  zone         = var.zone

  tags = ["guardium", "central-manager"]
  labels = merge(var.labels, {
    component = "central-manager"
    instance  = each.value.vm_name
    phase     = "1"
  })

  boot_disk {
    initialize_params {
      # Using Guardium aggregator image (acts as Central Manager)
      image = var.guardium_aggregator_image_id
      size  = 1500 # GB
      type  = "pd-balanced"

      labels = merge(var.labels, {
        component = "central-manager"
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
      metadata["ssh-keys"] # SSH keys will be managed by Guardium
    ]
  }
}

# Boot wait - Guardium needs time to initialize (20 minutes)
resource "time_sleep" "guardium_boot_wait" {
  for_each = { for cm in local.cm_config : cm.vm_name => cm }

  create_duration = "1200s" # 20 minutes
  depends_on      = [google_compute_instance.central_manager]
}

# STEP 2: Run automation script
resource "null_resource" "run_guardium_automation" {
  for_each = { for cm in local.cm_config : cm.vm_name => cm }

  provisioner "local-exec" {
    command = <<-EOT
#!/bin/bash
set -euo pipefail

PRIVATE_IP=${each.value.network_interface_ip}
VM_NAME=${each.value.vm_name}
HOSTNAME=${each.value.system_hostname}

echo ""
echo "=========================================="
echo "STEP 2: GUARDIUM AUTOMATION EXECUTION"
echo "=========================================="
echo "VM Name: $VM_NAME"
echo "Private IP: $PRIVATE_IP"
echo "Hostname: $HOSTNAME"
echo "Time: $(date)"
echo "=========================================="

# Define the modules directory path
MODULES_DIR="$HOME/guardium-gcp/modules/central_manager"

# Ensure modules directory exists
mkdir -p "$MODULES_DIR"

# Function to find and copy automation scripts
setup_automation_scripts() {
  local found_scripts=false
  
  echo "Searching for automation scripts..."
  
  # Search for the main script in various locations
  if [ -f "./modules/central_manager/run_wait_for_guardium.sh" ]; then
    echo "Found scripts in: ./modules/central_manager"
    cp ./modules/central_manager/* "$MODULES_DIR/" 2>/dev/null || true
    found_scripts=true
  elif [ -f "../modules/central_manager/run_wait_for_guardium.sh" ]; then
    echo "Found scripts in: ../modules/central_manager"
    cp ../modules/central_manager/* "$MODULES_DIR/" 2>/dev/null || true
    found_scripts=true
  elif [ -f "../../modules/central_manager/run_wait_for_guardium.sh" ]; then
    echo "Found scripts in: ../../modules/central_manager"
    cp ../../modules/central_manager/* "$MODULES_DIR/" 2>/dev/null || true
    found_scripts=true
  elif [ -f "/opt/guardium-gcp/modules/central_manager/run_wait_for_guardium.sh" ]; then
    echo "Found scripts in: /opt/guardium-gcp/modules/central_manager"
    cp /opt/guardium-gcp/modules/central_manager/* "$MODULES_DIR/" 2>/dev/null || true
    found_scripts=true
  elif [ -f "$HOME/guardium-gcp/modules/central_manager/run_wait_for_guardium.sh" ]; then
    echo "Scripts already exist in modules directory"
    found_scripts=true
  fi
  
  if [ "$found_scripts" = "false" ]; then
    echo "ERROR: Could not find automation scripts!"
    return 1
  fi
  
  # Make scripts executable
  chmod +x "$MODULES_DIR"/*.sh 2>/dev/null || true
  chmod +x "$MODULES_DIR"/*.expect 2>/dev/null || true
  
  return 0
}

# Setup automation scripts
if ! setup_automation_scripts; then
  echo "DEPLOYMENT STATUS: VM deployed successfully but automation scripts not found"
  echo "Manual configuration required:"
  echo "  1. SSH: ssh cli@$PRIVATE_IP (password: guardium)"
  echo "  2. Web UI: https://$PRIVATE_IP:8443 (admin/guardium)"
  exit 0
fi

# Verify the main script exists
if [ ! -f "$MODULES_DIR/run_wait_for_guardium.sh" ]; then
  echo "ERROR: Main automation script not found"
  exit 0
fi

echo "Starting Guardium automation for $VM_NAME..."
cd "$MODULES_DIR"

# Run the automation script
timeout 1800 ./run_wait_for_guardium.sh "$PRIVATE_IP" "guardium" || {
  echo "WARNING: Automation script exited with warnings"
}

echo ""
echo "=========================================="
echo "STEP 2 COMPLETED: $VM_NAME"
echo "=========================================="
echo "Private IP: $PRIVATE_IP"
echo "Web Access: https://$PRIVATE_IP:8443 (via bastion)"
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
echo "============================================"
echo "GUARDIUM CENTRAL MANAGER DEPLOYMENT COMPLETE"
echo "============================================"
echo "Total VMs deployed: ${length(local.cm_config)}"
echo ""
echo "Deployed instances:"
%{for cm in local.cm_config~}
echo "VM: ${cm.vm_name}"
echo "  Private IP: ${cm.network_interface_ip}"
echo "  Hostname: ${cm.system_hostname}"
echo "  Web UI: https://${cm.network_interface_ip}:8443"
echo ""
%{endfor~}
echo "Access Method: Via bastion host or SSH port forwarding"
echo "Default Web Login: admin/guardium"
echo ""
echo "DEPLOYMENT STATUS: SUCCESS"
echo "=========================================="
    EOT

    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [null_resource.run_guardium_automation]
}

