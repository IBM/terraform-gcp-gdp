# Automated installation of GDP appliances on GCP

## Scope

The modules contained here automate installation of GDP appliances onto GCP.

The following are supported:

* Central Manager
* Aggregator
* Collector

For background and detailed technical information, see the [full instructions document](docs/FULL_INSTRUCTIONS.md).

To get started deploying GDP machines, follow the instructions in each of the examples directories:
* [Bastion Host](examples/phase0bastion/README.md)
* [Central Manager](examples/phase1cm/README.md)
* [Aggregator](examples/phase2agg/README.md)
* [Collector](examples/phase3col/README.md)

## Summary of process

```
┌────────────────────────────────────────────────────┐
│                                                    │
│      Plan the installation, gather parameters      │
│                                                    │
└────────────────────────────────────────────────────┘
                          │
                          │
                          ▼
┌────────────────────────────────────────────────────┐
│                                                    │
│               Create the bastion host              │
│                                                    │
└────────────────────────────────────────────────────┘
                          │
                          │
                          ▼
┌────────────────────────────────────────────────────┐
│                                                    │
│             Create the Central Manager             │
│                                                    │
└────────────────────────────────────────────────────┘
                          │
                          │
                          ▼
┌────────────────────────────────────────────────────┐
│                                                    │
│        Manually enter license and configure        │
│                                                    │
└────────────────────────────────────────────────────┘
                          │
                          │
                          ▼
┌────────────────────────────────────────────────────┐
│                                                    │
│               Create the Aggregators               │
│                                                    │
└────────────────────────────────────────────────────┘
                          │
                          │
                          ▼
┌────────────────────────────────────────────────────┐
│                                                    │
│               Create the Collectors                │
│                                                    │
└────────────────────────────────────────────────────┘
```

## Process flow

1. Connect to GCP. Plan the installation. You will need the following items from GCP. You will probably have to get some of this information from your GCP administrator. The items you need are documented in the [phase0bastion README file](./examples/phase0bastion/README.md)

You will also need the following access keys.
* A `key.json` file that contains an access key for GCP with access to create new machines. You will probably need to get this from your GCP admin.
* A private/public SSH key pair for accessing the GDP machines. This can be created by you using the regular `ssh-keygen` command, and you will then add it in the GCP Console.

2. Run the Terraform process to create a bastion host. Details are in the [phase0bastion README file](./examples/phase0bastion/README.md).
3. Connect to the bastion host via SSH. All further work will be done from there.
4. Run the Terraform process to create a Central Manager.
5. Connect to GDP on the CM in a browser and accept the base license and add any other relevant licenses.
6. Run the `run_guardium_phase2.sh` script to convert the GDP machine to a Central Manager after the licenses have been accepted.
7. Run the Terraform process to create the Aggregators.
8. Run the Terraform process to create the Collectors.

## Prerequisites

### GCP

* Ability to login to GCP and view the instances and other information.
* A `key.json` file that contains an access key for GCP with access to create new machines.
* A private/public SSH key pair for accessing the GDP machines.

### Linux

* A clone of the GitHub repository for the Terraform scripts.
* Terraform

The documentation here assumes you will be using a Linux computer to run the Terrafrom process. Instructions to install these items will vary depending upon which Linux distribution you are using.

### GDP

* License (only required if you are creating a central manager)

## Usage

### Central Manager

Create a GDP Central Manager on GCP:

```hcl
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
```


### Aggregator

Create a GDP Aggregator on GCP:

```hcl
# modules/aggregator/main.tf (GCP Version)
# Aggregator module - private IP only with full Guardium automation

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

# Service account for Aggregator
resource "google_service_account" "agg_sa" {
  account_id   = "${var.vm_name}-sa"
  display_name = "${var.vm_name} Service Account"
  description  = "Service account for Guardium Aggregator ${var.vm_name}"
}

# IAM roles for Aggregator service account
resource "google_project_iam_member" "agg_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.agg_sa.email}"
}

# Aggregator Instance (Private IP only)
resource "google_compute_instance" "agg" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  tags   = ["guardium", "aggregator"]
  labels = var.labels

  boot_disk {
    initialize_params {
      # Using Guardium aggregator image
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
    email  = google_service_account.agg_sa.email
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
      echo "Guardium Aggregator ${var.vm_name} starting up..."
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
```


### Collector

Create a GDP Collector on GCP:

```hcl
# modules/collector/main.tf (GCP Version)
# Collector module - private IP only with full Guardium automation

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

# Service account for Collector
resource "google_service_account" "col_sa" {
  account_id   = "${var.vm_name}-sa"
  display_name = "${var.vm_name} Service Account"
  description  = "Service account for Guardium Collector ${var.vm_name}"
}

# IAM roles for Collector service account
resource "google_project_iam_member" "col_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.col_sa.email}"
}

# Collector Instance (Private IP only)
resource "google_compute_instance" "col" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  tags   = ["guardium", "collector"]
  labels = var.labels

  boot_disk {
    initialize_params {
      # Using Guardium collector image
      image = var.guardium_image_id
      size  = 500 # GB - smaller than aggregator
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
    email  = google_service_account.col_sa.email
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
      echo "Guardium Collector ${var.vm_name} starting up..."
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
```

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## Support

For issues and questions:
- Create an issue in this repository
- Contact the maintainers listed in [MAINTAINERS.md](MAINTAINERS.md)

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

```text
#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#
```

## Authors

Module is maintained by IBM with help from [these awesome contributors](https://github.com/IBM/terraform-guardium-datastore-va/graphs/contributors).
