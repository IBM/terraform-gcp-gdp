# modules/networking/variables.tf (GCP Private IP Version)

variable "network_name" {
  type        = string
  description = "Name of the VPC network"
  default     = "guardium-vpc"
}

variable "network_description" {
  type        = string
  description = "Description of the VPC network"
  default     = "Guardium VPC network"
}

variable "subnet_name" {
  type        = string
  description = "Name of the Guardium subnet"
  default     = "guardium-subnet"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR block for the Guardium subnet"
  default     = "10.0.0.0/24"
}

variable "guardium_subnet_description" {
  type        = string
  description = "Description of the Guardium subnet"
  default     = "Guardium instances subnet"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "firewall_name" {
  type        = string
  description = "Prefix for firewall rule names"
  default     = "guardium-firewall"
}

variable "private_mode" {
  type        = bool
  description = "Whether to run in private mode (restricts access to management subnet)"
  default     = true
}

variable "management_subnet_cidr" {
  type        = string
  description = "CIDR block for the management subnet (for bastion access)"
  default     = "10.0.1.0/24"
}

variable "allowed_management_ips" {
  type        = list(string)
  default     = []
  description = "List of allowed management IP addresses"
}

variable "create_vpc" {
  type        = bool
  description = "Whether to create a new VPC or use existing"
  default     = true
}

variable "create_subnet" {
  type        = bool
  description = "Whether to create a new subnet or use existing"
  default     = true
}

variable "create_nat" {
  type        = bool
  description = "Whether to create Cloud NAT for outbound internet access"
  default     = true
}

variable "create_firewalls" {
  type        = bool
  description = "Whether to create firewall rules (set to false if they already exist)"
  default     = true
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to all resources"
}

