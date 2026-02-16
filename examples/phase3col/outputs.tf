#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# examples/phase3col/outputs.tf

output "collector_private_ips" {
  description = "Private IP addresses of Collector instances"
  value       = { for k, v in google_compute_instance.collector : k => v.network_interface[0].network_ip }
}

output "collector_names" {
  description = "Names of Collector instances"
  value       = { for k, v in google_compute_instance.collector : k => v.name }
}

output "web_ui_urls" {
  description = "Web UI URLs for Collector instances"
  value       = { for k, v in google_compute_instance.collector : k => "https://${v.network_interface[0].network_ip}:8443" }
}

