#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# examples/phase2agg/outputs.tf

output "aggregator_private_ips" {
  description = "Private IP addresses of Aggregator instances"
  value       = { for k, v in google_compute_instance.aggregator : k => v.network_interface[0].network_ip }
}

output "aggregator_names" {
  description = "Names of Aggregator instances"
  value       = { for k, v in google_compute_instance.aggregator : k => v.name }
}

output "web_ui_urls" {
  description = "Web UI URLs for Aggregator instances"
  value       = { for k, v in google_compute_instance.aggregator : k => "https://${v.network_interface[0].network_ip}:8443" }
}

