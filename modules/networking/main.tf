# modules/networking/main.tf (GCP Private IP Version)
# Networking module with private IP restrictions

# Create VPC Network
resource "google_compute_network" "vpc" {
  count                   = var.create_vpc ? 1 : 0
  name                    = var.network_name
  auto_create_subnetworks = false
  mtu                     = 1460
  description             = var.network_description
}

# Data source for existing VPC
data "google_compute_network" "existing_vpc" {
  count = var.create_vpc ? 0 : 1
  name  = var.network_name
}

# Local to reference the VPC (created or existing)
locals {
  vpc_id        = var.create_vpc ? google_compute_network.vpc[0].id : data.google_compute_network.existing_vpc[0].id
  vpc_self_link = var.create_vpc ? google_compute_network.vpc[0].self_link : data.google_compute_network.existing_vpc[0].self_link
  vpc_name      = var.create_vpc ? google_compute_network.vpc[0].name : data.google_compute_network.existing_vpc[0].name
}

# Create Guardium Subnet
resource "google_compute_subnetwork" "guardium_subnet" {
  count         = var.create_subnet ? 1 : 0
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = local.vpc_id
  description   = var.guardium_subnet_description

  private_ip_google_access = true
}

# Data source for existing subnet
data "google_compute_subnetwork" "existing_subnet" {
  count  = var.create_subnet ? 0 : 1
  name   = var.subnet_name
  region = var.region
}

# Local to reference the subnet
locals {
  subnet_id        = var.create_subnet ? google_compute_subnetwork.guardium_subnet[0].id : data.google_compute_subnetwork.existing_subnet[0].id
  subnet_self_link = var.create_subnet ? google_compute_subnetwork.guardium_subnet[0].self_link : data.google_compute_subnetwork.existing_subnet[0].self_link
  subnet_name      = var.create_subnet ? google_compute_subnetwork.guardium_subnet[0].name : data.google_compute_subnetwork.existing_subnet[0].name
}

# Firewall: Allow SSH from management subnet only (Private mode)
resource "google_compute_firewall" "allow_ssh_from_management" {
  count   = var.create_firewalls ? 1 : 0
  name    = "${var.firewall_name}-allow-ssh-management"
  network = local.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.private_mode ? [var.management_subnet_cidr] : ["0.0.0.0/0"]
  target_tags   = ["guardium"]

  description = "Allow SSH access to Guardium from management subnet"
}

# Firewall: Allow Guardium Web UI from management subnet
resource "google_compute_firewall" "allow_guardium_web_management" {
  count   = var.create_firewalls ? 1 : 0
  name    = "${var.firewall_name}-allow-web-management"
  network = local.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }

  source_ranges = var.private_mode ? [var.management_subnet_cidr] : ["0.0.0.0/0"]
  target_tags   = ["guardium"]

  description = "Allow Guardium Web UI access from management subnet"
}

# Firewall: Allow HTTPS from management subnet
resource "google_compute_firewall" "allow_https_management" {
  count   = var.create_firewalls ? 1 : 0
  name    = "${var.firewall_name}-allow-https-management"
  network = local.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = var.private_mode ? [var.management_subnet_cidr] : ["0.0.0.0/0"]
  target_tags   = ["guardium"]

  description = "Allow HTTPS access from management subnet"
}

# Firewall: Allow MySQL internal communication
resource "google_compute_firewall" "allow_mysql" {
  count   = var.create_firewalls ? 1 : 0
  name    = "${var.firewall_name}-allow-mysql"
  network = local.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["guardium"]

  description = "Allow MySQL internal communication within VPC"
}

# Firewall: Allow Guardium Internal communication
resource "google_compute_firewall" "allow_guardium_internal" {
  count   = var.create_firewalls ? 1 : 0
  name    = "${var.firewall_name}-allow-internal"
  network = local.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["8447"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["guardium"]

  description = "Allow Guardium internal communication"
}

# Firewall: Allow Solr communication
resource "google_compute_firewall" "allow_solr" {
  count   = var.create_firewalls ? 1 : 0
  name    = "${var.firewall_name}-allow-solr"
  network = local.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["8983", "9983"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["guardium"]

  description = "Allow Solr communication"
}

# Firewall: Allow ICMP (ping) within VPC for network diagnostics
resource "google_compute_firewall" "allow_icmp_internal" {
  count   = var.create_firewalls ? 1 : 0
  name    = "${var.firewall_name}-allow-icmp-internal"
  network = local.vpc_id

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr, var.management_subnet_cidr]
  target_tags   = ["guardium"]

  description = "Allow ICMP (ping) within VPC for network diagnostics"
}

# Firewall: Allow S-TAP communication ports (collector/aggregator data transfer)
# Matches Azure: ports 16016-16025
resource "google_compute_firewall" "allow_stap_communication" {
  count   = var.create_firewalls ? 1 : 0
  name    = "${var.firewall_name}-allow-stap-communication"
  network = local.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["16016", "16017", "16018", "16019", "16020", "16021", "16022", "16023", "16024", "16025"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["guardium"]

  description = "Allow S-TAP communication ports (collector-aggregator-CM data transfer)"
}

# Firewall: Allow SSH between Guardium instances (internal)
resource "google_compute_firewall" "allow_ssh_internal" {
  count   = var.create_firewalls ? 1 : 0
  name    = "${var.firewall_name}-allow-ssh-internal"
  network = local.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["guardium"]

  description = "Allow SSH between Guardium instances for internal management"
}

# Firewall: Allow Guardium Web UI and HTTPS internal communication
# Matches Azure: ports 443, 8443, 8444, 9443
resource "google_compute_firewall" "allow_guardium_web_internal" {
  count   = var.create_firewalls ? 1 : 0
  name    = "${var.firewall_name}-allow-web-internal"
  network = local.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["443", "8443", "8444", "9443"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["guardium"]

  description = "Allow Guardium Web UI and HTTPS internal communication (incl. sniffer mgmt and alt HTTPS)"
}

# Firewall: Allow HTTP internal services
# Matches Azure: port 8080
resource "google_compute_firewall" "allow_http_internal" {
  count   = var.create_firewalls ? 1 : 0
  name    = "${var.firewall_name}-allow-http-internal"
  network = local.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["guardium"]

  description = "Allow HTTP internal services"
}

# Firewall: Allow JMX monitoring
# Matches Azure: port 7199
resource "google_compute_firewall" "allow_jmx" {
  count   = var.create_firewalls ? 1 : 0
  name    = "${var.firewall_name}-allow-jmx"
  network = local.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["7199"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["guardium"]

  description = "Allow JMX monitoring"
}

# Firewall: Allow all egress (outbound)
resource "google_compute_firewall" "allow_all_egress" {
  count     = var.create_firewalls ? 1 : 0
  name      = "${var.firewall_name}-allow-egress"
  network   = local.vpc_id
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]

  description = "Allow all outbound traffic"
}

# Cloud Router (for NAT)
resource "google_compute_router" "router" {
  count   = var.create_nat ? 1 : 0
  name    = "${var.network_name}-router"
  region  = var.region
  network = local.vpc_id
}

# Cloud NAT (for outbound internet access from private instances)
resource "google_compute_router_nat" "nat" {
  count                              = var.create_nat ? 1 : 0
  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.router[0].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
