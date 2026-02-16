#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/bastion/main.tf (GCP Version)
# Bastion Host module for secure access to private Guardium instances

# Get the existing VPC network
data "google_compute_network" "vpc" {
  name = var.network_name
}

# Create management subnet for bastion host
resource "google_compute_subnetwork" "management_subnet" {
  count         = var.create_management_subnet ? 1 : 0
  name          = var.management_subnet_name
  ip_cidr_range = var.management_subnet_cidr
  region        = var.region
  network       = data.google_compute_network.vpc.id
  description   = "Management subnet for bastion host"

  private_ip_google_access = true
}

# Data source for existing management subnet
data "google_compute_subnetwork" "existing_management_subnet" {
  count  = var.create_management_subnet ? 0 : 1
  name   = var.management_subnet_name
  region = var.region
}

# Local to reference the management subnet
locals {
  management_subnet_id = var.create_management_subnet ? google_compute_subnetwork.management_subnet[0].id : data.google_compute_subnetwork.existing_management_subnet[0].id
}

# Reserve static external IP for bastion
resource "google_compute_address" "bastion_ip" {
  count  = var.create_bastion_ip ? 1 : 0
  name   = "${var.bastion_name}-ip"
  region = var.region
}

# Data source for existing bastion IP
data "google_compute_address" "existing_bastion_ip" {
  count  = var.create_bastion_ip ? 0 : 1
  name   = "${var.bastion_name}-ip"
  region = var.region
}

# Local to reference the bastion IP
locals {
  bastion_ip_address = var.create_bastion_ip ? google_compute_address.bastion_ip[0].address : data.google_compute_address.existing_bastion_ip[0].address
}

# Firewall rule for SSH access to bastion from allowed IPs
resource "google_compute_firewall" "bastion_ssh" {
  count   = var.create_bastion_firewalls ? 1 : 0
  name    = "${var.bastion_name}-allow-ssh"
  network = data.google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_source_ips
  target_tags   = ["bastion"]

  description = "Allow SSH access to bastion from specified IP ranges"
}

# Firewall rule for bastion to access Guardium instances
resource "google_compute_firewall" "bastion_to_guardium" {
  count   = var.create_bastion_firewalls ? 1 : 0
  name    = "${var.bastion_name}-to-guardium"
  network = data.google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22", "8443", "443"]
  }

  source_tags = ["bastion"]
  target_tags = ["guardium"]

  description = "Allow bastion to access Guardium instances"
}

# Create bastion instance
resource "google_compute_instance" "bastion" {
  count        = var.create_bastion ? 1 : 0
  name         = var.bastion_name
  machine_type = var.bastion_machine_type
  zone         = var.zone

  tags   = ["bastion"]
  labels = var.labels

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = data.google_compute_network.vpc.id
    subnetwork = local.management_subnet_id

    network_ip = var.bastion_private_ip

    access_config {
      nat_ip = local.bastion_ip_address
    }
  }

  metadata = {
    ssh-keys = "${var.admin_username}:${var.ssh_public_key}"

    startup-script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y curl wget unzip jq expect software-properties-common apt-transport-https ca-certificates gnupg lsb-release netcat-openbsd

      curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
      apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
      apt-get update && apt-get install -y terraform

      echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
      curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
      apt-get update && apt-get install -y google-cloud-cli

      apt-get install -y htop tree vim git

      mkdir -p /home/${var.admin_username}/.ssh
      chown ${var.admin_username}:${var.admin_username} /home/${var.admin_username}/.ssh
      chmod 700 /home/${var.admin_username}/.ssh

      echo "Bastion setup completed" > /var/log/bastion-setup.log
    EOF
  }

  allow_stopping_for_update = true

  depends_on = [google_compute_subnetwork.management_subnet]
}

# Upload Terraform configs to bastion
resource "null_resource" "upload_terraform_configs" {
  count = var.create_bastion ? 1 : 0

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /tmp/guardium-gcp",
      "sudo mkdir -p /tmp/guardium-gcp",
      "sudo chown ${var.admin_username}:${var.admin_username} /tmp/guardium-gcp",
      "chmod 755 /tmp/guardium-gcp",
    ]

    connection {
      type        = "ssh"
      host        = local.bastion_ip_address
      user        = var.admin_username
      private_key = var.ssh_private_key
    }
  }

  provisioner "file" {
    source      = "${path.module}/../../modules"
    destination = "/tmp/guardium-gcp/modules"

    connection {
      type        = "ssh"
      host        = local.bastion_ip_address
      user        = var.admin_username
      private_key = var.ssh_private_key
    }
  }

  provisioner "file" {
    source      = "${path.module}/../../examples"
    destination = "/tmp/guardium-gcp/examples"

    connection {
      type        = "ssh"
      host        = local.bastion_ip_address
      user        = var.admin_username
      private_key = var.ssh_private_key
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /opt/guardium-gcp",
      "sudo mkdir -p /opt/guardium-gcp",
      "sudo cp -r /tmp/guardium-gcp/* /opt/guardium-gcp/",
      "sudo chown -R ${var.admin_username}:${var.admin_username} /opt/guardium-gcp",

      "find /opt/guardium-gcp -type f -name 'run_*.sh' -exec chmod +x {} \\;",
      "find /opt/guardium-gcp -type f -name '*.expect' -exec chmod +x {} \\;",

      # ----------------------------------------------------------
      # FIX: FULL APT LOCK HANDLING
      # ----------------------------------------------------------
      "echo '[INFO] Checking for active apt/dpkg processes...'",

      "while pgrep -x apt >/dev/null || " ,
      "      pgrep -x apt-get >/dev/null || " ,
      "      pgrep -x dpkg >/dev/null || " ,
      "      sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do " ,
      "        echo '[WAIT] apt/dpkg is busy... waiting 5 seconds'; sleep 5; " ,
      "done",

      "echo '[INFO] apt/dpkg lock is free — continuing...'",
      "sleep 3",

      # Install expect
      "sudo apt-get update -y",
      "sudo apt-get install -y expect",

      "echo 'Expect version:'",
      "expect -v || echo 'Expect installation failed!'",

      "echo 'Guardium Terraform modules successfully uploaded'",
      "ls -la /opt/guardium-gcp/"
    ]

    connection {
      type        = "ssh"
      host        = local.bastion_ip_address
      user        = var.admin_username
      private_key = var.ssh_private_key
    }
  }

  depends_on = [google_compute_instance.bastion]
}
