<p align="center">
  <img src="https://img.shields.io/badge/Terraform-%3E%3D1.6.0-623CE4?style=for-the-badge&logo=terraform" alt="Terraform">
  <img src="https://img.shields.io/badge/GCP-Cloud-4285F4?style=for-the-badge&logo=google-cloud" alt="GCP">
  <img src="https://img.shields.io/badge/IBM-Guardium%20V12.1.0-054ADA?style=for-the-badge&logo=ibm" alt="IBM Guardium">
  <img src="https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge" alt="License">
</p>

# 🛡️ IBM Guardium Data Protection V12.1.0 - GCP Private Cloud Deployment

A production-ready Terraform solution for deploying **IBM Guardium Data Protection V12.1.0** on Google Cloud Platform with enterprise-grade security using private networking and bastion host access.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [SSH Key Configuration](#ssh-key-configuration)
- [JSON Configuration Files](#json-configuration-files)
- [Module Reference](#module-reference)
- [Network Architecture](#network-architecture)
- [Security](#security)
- [Accessing Guardium](#accessing-guardium)
- [Logs and Monitoring](#logs-and-monitoring)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)
- [Cleanup](#cleanup)

---

## Overview

This project provides a comprehensive Infrastructure-as-Code (IaC) solution for deploying IBM Guardium Data Protection V12.1.0 on GCP. The deployment follows a **phased approach** with all Guardium components deployed in a private network with no public IP addresses, accessible only through a secure bastion host.

### What is IBM Guardium?

IBM Guardium Data Protection is an enterprise database activity monitoring (DAM) solution that provides:
- Real-time database activity monitoring
- Data security and compliance
- Automated audit reporting
- Vulnerability assessment
- Data discovery and classification

### Deployment Components

| Component | Description | Disk Size |
|-----------|-------------|-----------|
| **Central Manager** | Main management console, policy distribution, reporting | 1500 GB SSD |
| **Aggregator** | Aggregates data from collectors, intermediate processing | 1500 GB SSD |
| **Collector** | Monitors database traffic, collects activity data | 500 GB SSD |
| **Bastion Host** | Secure jump server for accessing private instances | 100 GB SSD |

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                              GCP Virtual Private Cloud (10.0.0.0/16)           │
│                                                                                │
│  ┌─────────────────────────────┐   ┌──────────────────────────────────────────┐│
│  │   Management Subnet         │   │         Guardium Subnet                  ││
│  │   10.0.1.0/24               │   │         10.0.0.0/24                      ││
│  │                             │   │                                          ││
│  │  ┌────────────────────┐     │   │  ┌─────────────┐  ┌─────────────┐        ││
│  │  │   Bastion Host     │     │   │  │Central Mgr 1│  │Central Mgr 2│        ││
│  │  │   10.0.1.10        │◄────┼───┼─►│  10.0.0.10  │  │  10.0.0.11  │        ││
│  │  │   (Public IP)      │     │   │  └─────────────┘  └─────────────┘        ││
│  │  └────────────────────┘     │   │                                          ││
│  │          ▲                  │   │  ┌─────────────┐  ┌─────────────┐        ││
│  │          │                  │   │  │ Aggregator 1│  │ Aggregator 2│        ││
│  └──────────┼──────────────────┘   │  │  10.0.0.15  │  │  10.0.0.16  │        ││
│             │                      │  └─────────────┘  └─────────────┘        ││
│             │                      │                                          ││
│             │                      │  ┌─────────────┐  ┌─────────────┐        ││
│             │                      │  │ Collector 1 │  │ Collector 2 │        ││
│             │                      │  │  10.0.0.20  │  │  10.0.0.21  │        ││
│             │                      │  └─────────────┘  └─────────────┘        ││
│             │                      │                                          ││
│             │                      └──────────────────────────────────────────┘│
│             │                                                                  │
│             │  ┌─────────────────────────────────────────────────────────────┐ │
│             │  │                    Cloud NAT                                │ │
│             │  │         (Outbound internet for private instances)           │ │
│             │  └─────────────────────────────────────────────────────────────┘ │
└─────────────┼──────────────────────────────────────────────────────────────────┘
              │
              │ SSH (Port 22)
              │ Restricted IPs
              ▼
        ┌───────────┐
        │ Admin     │
        │Workstation│
        └───────────┘
```

### Deployment Phases

| Phase | Component | Description | Duration |
|-------|-----------|-------------|----------|
| **Phase 0** | Infrastructure & Bastion | Creates VPC, subnets, firewall rules, Cloud NAT, and secure bastion host | ~10 min |
| **Phase 1** | Central Manager(s) | Deploys Guardium Central Manager instances | ~30 min |
| **Phase 1.5** | CM Post-Config ⭐ | Accept GUI license + run Phase 2 script (manual step) | ~10 min |
| **Phase 2** | Aggregator(s) | Deploys Guardium Aggregator instances | ~30 min |
| **Phase 3** | Collector(s) | Deploys Guardium Collector instances | ~30 min |

> ⭐ **Note:** Phase 1.5 is a manual step required after Central Manager deployment.

---

## Features

- ✅ **Private Networking** - All Guardium components use private IPs only
- ✅ **Secure Access** - Single bastion host with restricted IP access
- ✅ **Automated Configuration** - Expect scripts automate Guardium CLI setup
- ✅ **Phased Deployment** - Modular approach for controlled rollouts
- ✅ **JSON Configuration** - Easy multi-instance deployments via JSON files
- ✅ **High Availability** - Support for multiple CM, Aggregator, and Collector instances
- ✅ **GCP Best Practices** - Firewall rules, Cloud NAT, SSD storage
- ✅ **Infrastructure as Code** - Fully reproducible deployments
- ✅ **Deployment Logging** - Automatic log file generation for each deployment
- ✅ **Cloud NAT** - Outbound internet access for private instances without public IPs

---

## Prerequisites

### GCP Requirements

| Requirement | Description |
|-------------|-------------|
| **GCP Project** | Active project with billing enabled |
| **Service Account** | With Compute Admin, IAM Admin, and Network Admin roles |
| **gcloud CLI** | Installed and configured |
| **Guardium Images** | Custom Guardium images uploaded to GCP |
| **API Enabled** | Compute Engine API, IAM API |

### Required GCP IAM Roles

```
roles/compute.admin
roles/iam.serviceAccountAdmin
roles/iam.serviceAccountUser
roles/compute.networkAdmin
```

### Software Requirements

| Software | Version | Purpose |
|----------|---------|---------|
| **Terraform** | ≥ 1.6.0 | Infrastructure provisioning |
| **SSH Client** | Any | Bastion access |
| **jq** | Any | JSON processing |
| **expect** | Any | Automated CLI interactions |
| **nc (netcat)** | Any | Port connectivity testing |

Here is your section formatted exactly as GitHub Markdown code, ready to paste into README.md.

### IBM Guardium Requirements

The IBM Guardium Google Group is used **only** for sharing and accessing Guardium images in GCP.  
All documentation and deployment guides are available publicly from IBM:

**Guardium Documentation**  
https://www.ibm.com/docs/en/guardium

**Guardium on Cloud – Deployment Guides**  
https://www.ibm.com/support/pages/deploying-guardium-cloud

**IBM Guardium Community**  
https://community.ibm.com/community/user/security/communities/community-home?CommunityKey=aa1a6549-4b51-421a-9c67-6dd41e65ef85

**Downloading Guardium GDP Images**  
Customers must:

1. Subscribe to the IBM Guardium Google Group:  
   https://groups.google.com/g/ibmsecurityguardium
2. Use the **same email address** for both the Google Group subscription and your GCP account login.

Once subscribed and logged into GCP, you can launch an instance and select any Guardium image from the **“Guardium Images”** project.

---

### Additional Requirements

- Valid IBM Guardium V12.1.0 license keys  
- Guardium shared secret for component registration  
- Guardium VM images (Aggregator and Collector) available in GCP  
- Guardium image IDs retrieved from the GCP console  

---

## Quick Start

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/your-org/terraform-gcp-guardium.git
cd terraform-gcp-guardium
```

### 2️⃣ Configure GCP Credentials

#### Authenticate with GCP

```bash
# Login and select project
gcloud auth login
gcloud config set project <YOUR_PROJECT_ID>

# (Optional) Set a default region/zone
gcloud config set compute/region us-central1
gcloud config set compute/zone   us-central1-a
```

#### Service Account (for non-interactive/automated runs)

Create a service account key and save it as `key.json` in each example directory, then export:

```bash
Save the key.json in each phase in terraform-gcp-guardium/example/  folder.
```

#### Create `examples/phase0bastion/terraform.tfvars`

```hcl
project_id       = "your-project-id"
region           = "us-central1"
zone             = "us-central1-a"
credentials_file = "./key.json"

ssh_public_key  = "ssh-rsa AAAAB3... your-public-key"
ssh_private_key = <<-EOT
-----BEGIN OPENSSH PRIVATE KEY-----
your-private-key-content
-----END OPENSSH PRIVATE KEY-----
EOT

allowed_source_ips = ["YOUR.PUBLIC.IP/32"]
```

### 3️⃣ Deploy Phase 0 (Bastion)

```bash
cd examples/phase0bastion
terraform init
terraform plan
terraform apply
```

### 4️⃣ Continue from Bastion Host

```bash
# SSH to bastion
ssh gcpuser@<bastion-public-ip>

# Navigate to deployment directory
cd /opt/guardium-gcp/examples

# Deploy Central Manager
cd phase1cm && terraform init && terraform apply

# ⚠️ IMPORTANT: After Phase 1 completes:
# 1. Accept license in GUI (https://localhost:8443 via SSH tunnel)
# 2. Run Phase 2 configuration script:
cd /opt/guardium-gcp/modules/central_manager
chmod +x run_guardium_phase2.sh
./run_guardium_phase2.sh 10.0.0.10 'YOUR_PASSWORD' YOUR_SHARED_SECRET

# Continue with Aggregators and Collectors
cd /opt/guardium-gcp/examples/phase2agg && terraform init && terraform apply
cd ../phase3col && terraform init && terraform apply
```

---

## SSH Key Configuration

The bastion host requires SSH keys for secure access. Here are the different methods to configure them:

### Option 1: Generate New SSH Keys (Recommended)

```bash
# Generate a new SSH key pair specifically for this deployment
ssh-keygen -t rsa -b 4096 -C "guardium-gcp-deployment" -f ~/.ssh/guardium-gcp

# This creates:
# - ~/.ssh/guardium-gcp      (private key)
# - ~/.ssh/guardium-gcp.pub  (public key)
```

View the keys to copy into terraform.tfvars:

```bash
# View public key (copy this for ssh_public_key)
cat ~/.ssh/guardium-gcp.pub

# View private key (copy this for ssh_private_key)
cat ~/.ssh/guardium-gcp
```

### Option 2: Inline in terraform.tfvars

```hcl
# examples/phase0bastion/terraform.tfvars

# SSH Public Key - paste the ENTIRE line from ~/.ssh/guardium-gcp.pub
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDxxxxxxxxx== guardium-gcp-deployment"

# SSH Private Key - paste the ENTIRE content from ~/.ssh/guardium-gcp
ssh_private_key = <<-EOT
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAACFwAAAAdzc2gtcn
NhAAAAAwEAAQAAAgEAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
-----END OPENSSH PRIVATE KEY-----
EOT
```

### Option 3: Use a Separate Secrets File (More Secure)

Create `examples/phase0bastion/secrets.auto.tfvars`:

```hcl
# examples/phase0bastion/secrets.auto.tfvars
# ⚠️ This file is auto-loaded by Terraform

ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAA... your-full-public-key"

ssh_private_key = <<-EOT
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAACFwAAAAdzc2gtcn
... your full private key content ...
-----END OPENSSH PRIVATE KEY-----
EOT
```

### Option 4: Use Environment Variables

```bash
# Set environment variables (works on Linux/macOS)
export TF_VAR_ssh_public_key="$(cat ~/.ssh/guardium-gcp.pub)"
export TF_VAR_ssh_private_key="$(cat ~/.ssh/guardium-gcp)"

# Then run terraform (it will pick up TF_VAR_* automatically)
cd examples/phase0bastion
terraform apply
```

### Important Notes

| ⚠️ Warning | Description |
|------------|-------------|
| **Never commit private keys** | Add `*.auto.tfvars` and key files to `.gitignore` |
| **Use complete key content** | Include the entire `-----BEGIN...` to `-----END...` block |
| **No extra whitespace** | Ensure no trailing spaces or extra newlines in key content |
| **Heredoc syntax** | The `<<-EOT ... EOT` format allows multi-line strings with proper formatting |
| **Key permissions** | Private keys should have `chmod 600` permissions |

---

## JSON Configuration Files

Each phase uses a JSON configuration file for multi-instance deployments.

### Central Manager Configuration (`central_manager_config.json`)

```json
{
  "central_managers": [
    {
      "vm_name": "cm01",
      "system_hostname": "cm01",
      "network_interface_ip": "10.0.0.10",
      "system_domain": "guardium.internal",
      "network_interface_mask": "/24",
      "network_routes_defaultroute": "10.0.0.1",
      "network_resolvers1": "169.254.169.254",
      "network_resolvers2": "8.8.8.8",
      "system_clock_timezone": "America/New_York",
      "guardium_cli_default_password": "guardium",
      "guardium_final_pw": "YourSecurePassword123!",
      "guardium_shared_secret": "YourSharedSecret",
      "guardium_central_manager_ip": "10.0.0.10",
      "guardium_license_key": "YOUR_LICENSE_KEY_HERE"
    }
  ]
}
```

### Aggregator Configuration (`aggregator_config.json`)

```json
{
  "aggregators": [
    {
      "vm_name": "agg01",
      "system_hostname": "agg01",
      "network_interface_ip": "10.0.0.15",
      "system_domain": "guardium.internal",
      "network_interface_mask": "/24",
      "network_routes_defaultroute": "10.0.0.1",
      "network_resolvers1": "169.254.169.254",
      "network_resolvers2": "8.8.8.8",
      "system_clock_timezone": "America/New_York",
      "guardium_cli_default_password": "guardium",
      "guardium_final_pw": "YourSecurePassword123!",
      "guardium_shared_secret": "YourSharedSecret",
      "guardium_central_manager_ip": "10.0.0.10",
      "guardium_license_key": "YOUR_LICENSE_KEY_HERE"
    }
  ]
}
```

### Collector Configuration (`collector_config.json`)

```json
{
  "collectors": [
    {
      "vm_name": "col01",
      "system_hostname": "col01",
      "network_interface_ip": "10.0.0.20",
      "system_domain": "guardium.internal",
      "network_interface_mask": "/24",
      "network_routes_defaultroute": "10.0.0.1",
      "network_resolvers1": "169.254.169.254",
      "network_resolvers2": "8.8.8.8",
      "system_clock_timezone": "America/New_York",
      "guardium_cli_default_password": "guardium",
      "guardium_final_pw": "YourSecurePassword123!",
      "guardium_shared_secret": "YourSharedSecret",
      "guardium_central_manager_ip": "10.0.0.10",
      "guardium_license_key": "YOUR_LICENSE_KEY_HERE"
    }
  ]
}
```

### JSON Configuration Fields

| Field | Type | Description |
|-------|------|-------------|
| `vm_name` | string | GCP VM instance name |
| `system_hostname` | string | Guardium system hostname |
| `network_interface_ip` | string | Static private IP address |
| `system_domain` | string | Domain name for FQDN |
| `network_interface_mask` | string | Subnet mask (CIDR format: `/24`) |
| `network_routes_defaultroute` | string | Default gateway IP |
| `network_resolvers1` | string | Primary DNS server |
| `network_resolvers2` | string | Secondary DNS server (optional) |
| `system_clock_timezone` | string | System timezone (e.g., `America/New_York`) |
| `guardium_cli_default_password` | string | Initial CLI password (default: `guardium`) |
| `guardium_final_pw` | string | Final password after setup |
| `guardium_shared_secret` | string | Shared secret for component registration |
| `guardium_central_manager_ip` | string | Central Manager IP for registration |
| `guardium_license_key` | string | IBM Guardium license key |

---

## Module Reference

### Project Structure

```
terraform-gcp-private/
├── modules/
│   ├── bastion/                    # Bastion host module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── central_manager/            # Central Manager module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── logs/                   # 📁 Deployment logs directory
│   │   ├── run_wait_for_guardium.sh
│   │   ├── wait_for_guardium.expect
│   │   ├── run_guardium_phase2.sh
│   │   └── wait_for_guardium_phase2.expect
│   ├── aggregator/                 # Aggregator module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── logs/                   # 📁 Deployment logs directory
│   │   ├── run_wait_for_guardium.sh
│   │   └── wait_for_guardium.expect
│   ├── collector/                  # Collector module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── logs/                   # 📁 Deployment logs directory
│   │   ├── run_wait_for_guardium.sh
│   │   └── wait_for_guardium.expect
│   └── networking/                 # Network infrastructure module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── examples/
│   ├── phase0bastion/              # Phase 0: Bastion deployment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── key.json
│   ├── phase1cm/                   # Phase 1: Central Manager deployment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   ├── central_manager_config.json
│   │   └── key.json
│   ├── phase2agg/                  # Phase 2: Aggregator deployment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   ├── aggregator_config.json
│   │   └── key.json
│   └── phase3col/                  # Phase 3: Collector deployment
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       ├── collector_config.json
│       └── key.json
├── .gitignore
├── versions.tf
└── README.md
```

### Module: Central Manager

#### Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project_id` | string | ✅ | - | GCP Project ID |
| `region` | string | ✅ | - | GCP region |
| `zone` | string | ✅ | - | GCP zone |
| `network_name` | string | ✅ | - | VPC network name |
| `subnet_name` | string | ✅ | - | Subnet name |
| `vm_name` | string | ✅ | - | VM instance name |
| `machine_type` | string | ❌ | `n2-highmem-4` | GCP machine type |
| `guardium_image_id` | string | ✅ | - | Guardium aggregator image ID |
| `private_ip` | string | ✅ | - | Static private IP address |
| `host_name` | string | ✅ | - | System hostname |
| `domain_name` | string | ✅ | - | System domain name |
| `subnet_mask` | string | ✅ | - | Subnet mask (CIDR or dotted) |
| `default_gateway` | string | ✅ | - | Default gateway IP |
| `resolver_1` | string | ✅ | - | Primary DNS resolver |
| `resolver_2` | string | ❌ | `null` | Secondary DNS resolver |
| `timezone` | string | ❌ | `America/New_York` | System timezone |
| `guardium_default_pw` | string | ❌ | `guardium` | Initial CLI password |
| `guardium_final_pw` | string | ✅ | - | Final password |
| `guardium_shared_secret` | string | ✅ | - | Shared secret |
| `guardium_license_key` | string | ✅ | - | License key |
| `guardium_central_manager_ip` | string | ✅ | - | Central Manager IP |
| `phase` | string | ❌ | `1` | Deployment phase (`1` or `2`) |
| `labels` | map(string) | ❌ | `{}` | GCP labels |

#### Outputs

| Name | Description |
|------|-------------|
| `vm_name` | Name of the Central Manager VM |
| `private_ip` | Private IP address |
| `instance_id` | GCP instance ID |
| `self_link` | Self link of the instance |
| `zone` | Zone of the instance |
| `service_account_email` | Service account email |
| `web_ui_url` | Guardium Web UI URL |
| `ssh_command` | SSH command to connect |
| `logs_directory` | Path to deployment logs |

### Module: Aggregator

#### Inputs

Same as Central Manager module with these differences:
- Default `phase` is `2`
- Uses `guardium_aggregator_image_id`

### Module: Collector

#### Inputs

Same as Central Manager module with these differences:
- Default `phase` is `3`
- Uses `guardium_collector_image_id`
- Default disk size is 500 GB (smaller than aggregator)

### Module: Bastion

#### Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project_id` | string | ✅ | - | GCP Project ID |
| `region` | string | ✅ | - | GCP region |
| `zone` | string | ✅ | - | GCP zone |
| `network_name` | string | ✅ | - | VPC network name |
| `subnet_name` | string | ✅ | - | Guardium subnet name |
| `management_subnet_name` | string | ❌ | `management-subnet` | Management subnet name |
| `management_subnet_cidr` | string | ❌ | `10.0.1.0/24` | Management subnet CIDR |
| `guardium_subnet_cidr` | string | ❌ | `10.0.0.0/24` | Guardium subnet CIDR |
| `bastion_name` | string | ❌ | `guardium-bastion` | Bastion hostname |
| `bastion_machine_type` | string | ❌ | `e2-standard-2` | Bastion machine type |
| `bastion_private_ip` | string | ❌ | `10.0.1.10` | Bastion private IP |
| `allowed_source_ips` | list(string) | ✅ | - | Allowed SSH source IPs |
| `admin_username` | string | ❌ | `gcpuser` | Admin username |
| `ssh_private_key` | string | ✅ | - | SSH private key |
| `labels` | map(string) | ❌ | `{}` | GCP labels |

---

## Network Architecture

### IP Addressing Scheme

| Component | IP Range | Example IPs |
|-----------|----------|-------------|
| **Management Subnet** | 10.0.1.0/24 | |
| - Bastion Host | 10.0.1.10 | 10.0.1.10 |
| **Guardium Subnet** | 10.0.0.0/24 | |
| - Central Managers | 10.0.0.10-14 | 10.0.0.10, 10.0.0.11 |
| - Aggregators | 10.0.0.15-19 | 10.0.0.15, 10.0.0.16 |
| - Collectors | 10.0.0.20-29 | 10.0.0.20, 10.0.0.21 |

### Firewall Rules

| Rule | Ports | Source | Target | Description |
|------|-------|--------|--------|-------------|
| `bastion-allow-ssh` | 22 | Allowed IPs | bastion | SSH to bastion |
| `bastion-to-guardium` | 22, 443, 8443 | bastion | guardium | Bastion access |
| `allow-ssh-management` | 22 | Management subnet | guardium | SSH from mgmt |
| `allow-guardium-web` | 8443 | Management subnet | guardium | Web UI |
| `allow-mysql` | 3306 | Guardium subnet | guardium | Internal DB |
| `allow-guardium-internal` | 8447 | Guardium subnet | guardium | Component comm |
| `allow-solr` | 8983, 9983 | Guardium subnet | guardium | Search indexing |
| `allow-egress` | All | Guardium subnet | Internet | Outbound (via NAT) |

### GCP Machine Types

| Component | Recommended Type | vCPUs | Memory | Disk |
|-----------|-----------------|-------|--------|------|
| Bastion Host | e2-standard-2 | 2 | 8 GB | 100 GB |
| Central Manager | n2-highmem-4 | 4 | 32 GB | 1500 GB SSD |
| Aggregator | n2-highmem-4 | 4 | 32 GB | 1500 GB SSD |
| Collector | n2-highmem-4 | 4 | 32 GB | 500 GB SSD |

---

## Accessing Guardium

### SSH Access

```bash
# Connect to bastion host
ssh -i ~/.ssh/guardium-gcp gcpuser@<bastion-public-ip>

# From bastion, access Guardium CLI
ssh cli@10.0.0.10    # Central Manager
ssh cli@10.0.0.15    # Aggregator
ssh cli@10.0.0.20    # Collector
```

### Web Interface Access (Port Forwarding)

```bash
# Forward Guardium Web UI through bastion
ssh -L 8443:10.0.0.10:8443 -i ~/.ssh/guardium-gcp gcpuser@<bastion-public-ip>

# Then open in browser
https://localhost:8443
```

### Multiple Port Forwarding

```bash
# Forward multiple Guardium instances
ssh -L 8443:10.0.0.10:8443 \
    -L 8444:10.0.0.15:8443 \
    -L 8445:10.0.0.20:8443 \
    -i ~/.ssh/guardium-gcp gcpuser@<bastion-public-ip>

# Access:
# Central Manager: https://localhost:8443
# Aggregator:      https://localhost:8444
# Collector:       https://localhost:8445
```

### Default Credentials

| Component | Username | Default Password |
|-----------|----------|------------------|
| Guardium CLI | `cli` | `guardium` (changed during setup) |
| Guardium Web UI | `admin` | (set during deployment) |

---

## Logs and Monitoring

### Deployment Logs

Each module automatically generates timestamped log files during deployment.

#### Log File Locations

| Module | Log Directory |
|--------|---------------|
| Central Manager | `modules/central_manager/logs/` |
| Aggregator | `modules/aggregator/logs/` |
| Collector | `modules/collector/logs/` |

#### Log File Naming Convention

```
{vm_name}_{YYYYMMDD_HHMMSS}.log
```

**Examples:**
- `cm01_20251204_143022.log`
- `agg01_20251204_150532.log`
- `col01_20251204_160842.log`

#### Log Contents

Each log file contains:
- Deployment phase information
- VM creation details
- SSH connectivity checks
- Guardium CLI automation output
- Configuration steps and results
- Timestamps for each step
- Any errors or warnings

#### Viewing Logs

```bash
# List all logs for Central Manager
ls -la modules/central_manager/logs/

# View latest log
cat modules/central_manager/logs/cm01_20251204_143022.log

# Follow log in real-time during deployment (from another terminal)
tail -f modules/central_manager/logs/*.log

# Search for errors in logs
grep -i "error\|fail\|warning" modules/*/logs/*.log
```

#### Log Retention

Logs are **not tracked by git** (excluded in `.gitignore`). They persist locally between Terraform runs with unique timestamps, allowing you to compare deployments.

### GCP Console Monitoring

```bash
# View VM serial console output
gcloud compute instances get-serial-port-output <vm-name> --zone=<zone>

# View VM status
gcloud compute instances describe <vm-name> --zone=<zone>

# List all Guardium VMs
gcloud compute instances list --filter="tags.items:guardium"
```

---

## Troubleshooting

### Common Issues

#### 1. SSH Connection Timeout

```bash
# Verify bastion is reachable
nc -zv <bastion-public-ip> 22

# Check your source IP is allowed
curl ifconfig.me

# Verify your IP is in allowed_source_ips
```

#### 2. Guardium Not Responding After Deployment

Guardium requires **~20 minutes** to fully initialize after VM creation.

```bash
# Check VM status
gcloud compute instances describe cm01 --zone=us-central1-a

# View serial console output
gcloud compute instances get-serial-port-output cm01 --zone=us-central1-a

# Check deployment logs
cat modules/central_manager/logs/cm01_*.log
```

#### 3. Automation Script Fails

```bash
# Check log files for errors
grep -i error modules/central_manager/logs/*.log

# Make script executable
chmod +x /opt/guardium-gcp/modules/central_manager/run_wait_for_guardium.sh

# Run manually with debug
bash -x ./run_wait_for_guardium.sh 10.0.0.10 "guardium"
```

#### 4. JSON Configuration Not Found

```bash
# Verify JSON file exists
ls -la examples/phase1cm/central_manager_config.json

# Validate JSON syntax
jq . examples/phase1cm/central_manager_config.json
```

#### 5. Terraform State Issues

```bash
# Refresh state
terraform refresh

# View current state
terraform state list

# Remove problematic resource from state
terraform state rm <resource_address>
```

#### 6. Port Forwarding Not Working

```bash
# Check if port is already in use locally
lsof -i :8443

# Verify Guardium is listening on the VM
ssh cli@10.0.0.10 "netstat -tlnp | grep 8443"

# Test from bastion
nc -zv 10.0.0.10 8443
```

#### 7. Password Change Failed

```bash
# Try default password first
ssh cli@10.0.0.10  # password: guardium

# If that fails, check logs for the final password
grep -i "password\|final_pw" modules/central_manager/logs/*.log
```

### Diagnostic Commands

```bash
# Check all Guardium instances
for ip in 10.0.0.10 10.0.0.15 10.0.0.20; do
  echo "=== Testing $ip ==="
  nc -zv $ip 22 && echo "SSH: OK" || echo "SSH: FAILED"
  nc -zv $ip 8443 && echo "Web: OK" || echo "Web: FAILED"
done

# Check firewall rules
gcloud compute firewall-rules list --filter="network:guardium-vpc"

# Check Cloud NAT status
gcloud compute routers get-nat-mapping-info guardium-vpc-router --region=us-central1
```

---

## Maintenance

### Updating Guardium Configuration

1. Modify the JSON configuration file
2. Run `terraform plan` to see changes
3. Run `terraform apply` to apply changes

### Scaling (Adding More Instances)

1. Add new entries to the JSON configuration file
2. Run `terraform apply`

**Example - Adding a second aggregator:**

```json
{
  "aggregators": [
    {
      "vm_name": "agg01",
      "network_interface_ip": "10.0.0.15",
      ...
    },
    {
      "vm_name": "agg02",
      "network_interface_ip": "10.0.0.16",
      ...
    }
  ]
}
```

### Backup and Recovery

```bash
# Backup Terraform state
cp terraform.tfstate terraform.tfstate.backup

# Export current configuration
terraform show -json > current_config.json
```

---

## Cleanup

Destroy resources in **reverse order**:

```bash
# Phase 3: Destroy Collectors
cd /opt/guardium-gcp/examples/phase3col
terraform destroy -auto-approve

# Phase 2: Destroy Aggregators
cd /opt/guardium-gcp/examples/phase2agg
terraform destroy -auto-approve

# Phase 1: Destroy Central Managers
cd /opt/guardium-gcp/examples/phase1cm
terraform destroy -auto-approve

# Phase 0: Destroy Infrastructure (from local machine)
cd examples/phase0bastion
terraform destroy -auto-approve
```

⚠️ **Warning:** Destroying Phase 0 from the bastion will terminate your SSH session. Run Phase 0 destroy from your local machine.

### Partial Cleanup

```bash
# Destroy specific resource
terraform destroy -target=module.central_manager

# Destroy with auto-approve (use with caution)
terraform destroy -auto-approve
```

---

## Security Best Practices

1. **Restrict Bastion Access** - Only allow specific IP addresses in `allowed_source_ips`
2. **Use Strong Passwords** - Set complex passwords in JSON configuration
3. **Rotate Credentials** - Periodically change Guardium passwords and shared secrets
4. **Monitor Access** - Review GCP audit logs for SSH and API access
5. **Update Images** - Keep Guardium images updated with latest patches
6. **Backup State** - Store Terraform state in GCS with versioning enabled
7. **Use Secrets Manager** - Consider using GCP Secret Manager for sensitive values

---

## Support

For issues related to:
- **IBM Guardium**: Contact IBM Support
- **GCP Infrastructure**: Contact Google Cloud Support
- **This Terraform Module**: Open an issue in this repository

---

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

```text
#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#
```

---

## Changelog

### v1.0.0
- Initial release
- Support for Central Manager, Aggregator, and Collector deployment
- Private networking with bastion host
- Automated Guardium CLI configuration
- JSON-based multi-instance deployment
- Deployment logging

---
