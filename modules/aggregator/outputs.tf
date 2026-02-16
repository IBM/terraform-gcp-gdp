#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/aggregator/outputs.tf (GCP Version)

output "vm_name" {
  description = "Name of the Aggregator VM"
  value       = google_compute_instance.agg.name
}

output "private_ip" {
  description = "Private IP address of the Aggregator"
  value       = google_compute_instance.agg.network_interface[0].network_ip
}

output "instance_id" {
  description = "Instance ID of the Aggregator"
  value       = google_compute_instance.agg.instance_id
}

output "self_link" {
  description = "Self link of the Aggregator instance"
  value       = google_compute_instance.agg.self_link
}

output "zone" {
  description = "Zone of the Aggregator"
  value       = google_compute_instance.agg.zone
}

output "service_account_email" {
  description = "Service account email for the Aggregator"
  value       = google_service_account.agg_sa.email
}

output "web_ui_url" {
  description = "URL for the Guardium Web UI (via bastion port forwarding)"
  value       = "https://${google_compute_instance.agg.network_interface[0].network_ip}:8443"
}

output "ssh_command" {
  description = "SSH command to connect to Aggregator (via bastion)"
  value       = "ssh cli@${google_compute_instance.agg.network_interface[0].network_ip}"
}

output "logs_directory" {
  description = "Path to the logs directory for this Aggregator deployment"
  value       = "${path.module}/logs"
}

