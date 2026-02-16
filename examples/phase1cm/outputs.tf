#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# examples/phase1cm/outputs.tf

output "central_manager_private_ips" {
  description = "Private IP addresses of Central Manager instances"
  value       = { for k, v in google_compute_instance.central_manager : k => v.network_interface[0].network_ip }
}

output "central_manager_names" {
  description = "Names of Central Manager instances"
  value       = { for k, v in google_compute_instance.central_manager : k => v.name }
}

output "web_ui_urls" {
  description = "Web UI URLs for Central Manager instances"
  value       = { for k, v in google_compute_instance.central_manager : k => "https://${v.network_interface[0].network_ip}:8443" }
}

