#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/central_manager/main.tf (GCP Version)
# Central Manager module - private IP only with full Guardium automation

locals {
  # Convert CIDR notation to subnet mask for Guardium CLI
  mask_lookup = {
    "/27" = "255.255.255.224"
    "/25" = "255.255.255.128"
    "/24" = "255.255.255.0"
    "/23" = "255.255.254.0"
    "/20" = "255.255.240.0"
    "/16" = "255.255.0.0"
  }

  dotted_mask = lookup(local.mask_lookup, var.subnet_mask, var.subnet_mask)
}

# Get existing network and subnet
data "google_compute_network" "vpc" {
  name = var.network_name
}

data "google_compute_subnetwork" "guardium_subnet" {
  name   = var.subnet_name
  region = var.region
}

# Service account for Central Manager
resource "google_service_account" "cm_sa" {
  account_id   = "${var.vm_name}-sa"
  display_name = "${var.vm_name} Service Account"
  description  = "Service account for Guardium Central Manager ${var.vm_name}"
}

# IAM roles for Central Manager service account
resource "google_project_iam_member" "cm_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.cm_sa.email}"
}

# Central Manager Instance (Private IP only)
resource "google_compute_instance" "cm" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  tags   = ["guardium", "central-manager"]
  labels = var.labels

  boot_disk {
    initialize_params {
      # Using Guardium aggregator image (configured as Central Manager)
      image = var.guardium_image_id
      size  = 1500 # GB - matching Azure setup
      type  = "pd-ssd"

      labels = var.labels
    }
  }

  network_interface {
    network    = data.google_compute_network.vpc.id
    subnetwork = data.google_compute_subnetwork.guardium_subnet.id

    # Static private IP - NO external IP for private deployment
    network_ip = var.private_ip

    # No access_config block = no external IP (private only)
  }

  service_account {
    email  = google_service_account.cm_sa.email
    scopes = ["cloud-platform"]
  }

  # Metadata for Guardium configuration
  metadata = {
    # Guardium-specific metadata
    guardium-hostname = var.host_name
    guardium-domain   = var.domain_name
    guardium-timezone = var.timezone

    # Network configuration
    guardium-private-ip = var.private_ip
    guardium-netmask    = local.dotted_mask
    guardium-gateway    = var.default_gateway
    guardium-dns1       = var.resolver_1
    guardium-dns2       = var.resolver_2 != null ? var.resolver_2 : ""

    # Set hostname properly for GCP
    hostname = lower(join(".", [var.host_name, "internal"]))

    # Startup script for basic initialization
    startup-script = <<-EOF
      #!/bin/bash
      # Basic startup script for GCP Guardium instance
      echo "Guardium Central Manager ${var.vm_name} starting up..."
      echo "Private IP: ${var.private_ip}"
      echo "Hostname: ${var.host_name}.${var.domain_name}"
      echo "Startup completed at $(date)" > /var/log/guardium-gcp-startup.log
    EOF
  }

  # Allow stopping for updates
  allow_stopping_for_update = true

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"] # SSH keys will be managed by Guardium after setup
    ]
  }
}

# Boot wait - Guardium needs time to initialize (20 minutes)
resource "time_sleep" "guardium_boot_wait" {
  create_duration = "1200s" # 20 minutes - same as Azure
  depends_on      = [google_compute_instance.cm]
}

# Automated Guardium CLI configuration via Expect
resource "null_resource" "wait_for_ssh" {
  provisioner "local-exec" {
    interpreter = ["/usr/bin/env", "bash", "-c"]

    command = <<EOT
set -euo pipefail

PRIVATE_IP='${var.private_ip}'
VM_NAME='${var.vm_name}'
MODULE_PATH='${abspath(path.module)}'

echo ""
echo "=========================================="
echo "PHASE 1: $VM_NAME DEPLOYMENT (PRIVATE GCP)"
echo "Private IP: $PRIVATE_IP"
echo "=========================================="
echo "[$(date '+%H:%M:%S')] VM deployed successfully"
echo "[$(date '+%H:%M:%S')] Waiting for Guardium to be ready..."

# --- Extra wait after VM create ---
sleep 300

# -------------------------------
# SSH READINESS CHECK
# -------------------------------
echo "[$(date '+%H:%M:%S')] Testing SSH port 22 on $PRIVATE_IP..."
for i in $(seq 1 30); do
  if timeout 5 bash -c "echo > /dev/tcp/$PRIVATE_IP/22" 2>/dev/null; then
    echo "[$(date '+%H:%M:%S')] TCP port 22 is open on $PRIVATE_IP"
    break
  fi
  echo "Attempt $i: SSH port not ready yet, waiting..."
  sleep 30
done

# -------------------------------
# START EXPECT AUTOMATION (logging handled by script)
# -------------------------------
echo "[$(date '+%H:%M:%S')] Starting Guardium configuration for $PRIVATE_IP..."
cd "$MODULE_PATH"
chmod +x run_wait_for_guardium.sh wait_for_guardium.expect 2>/dev/null || true

if [ -f "./run_wait_for_guardium.sh" ]; then
  ./run_wait_for_guardium.sh \
    '${var.private_ip}' \
    '${var.guardium_final_pw}' \
    || echo "Configuration completed with warnings"
else
  echo "WARNING: run_wait_for_guardium.sh not found in $MODULE_PATH"
  echo "Manual configuration may be required"
fi

echo "[$(date '+%H:%M:%S')] Guardium configuration completed for $VM_NAME"
echo "=========================================="
EOT
  }

  triggers = {
    private_ip = var.private_ip
    vm_name    = var.vm_name
    phase      = var.phase
    fingerprint = sha256(jsonencode({
      subnet_mask     = var.subnet_mask
      resolver_1      = var.resolver_1
      resolver_2      = var.resolver_2
      host_name       = var.host_name
      domain_name     = var.domain_name
      timezone        = var.timezone
      license_key     = var.guardium_license_key
      shared_secret   = var.guardium_shared_secret
      cm_ip           = var.guardium_central_manager_ip
      final_pw        = var.guardium_final_pw
    }))
  }

  depends_on = [time_sleep.guardium_boot_wait]
}

