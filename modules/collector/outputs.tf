#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/collector/outputs.tf (GCP Version)

output "vm_name" {
  description = "Name of the Collector VM"
  value       = google_compute_instance.col.name
}

output "private_ip" {
  description = "Private IP address of the Collector"
  value       = google_compute_instance.col.network_interface[0].network_ip
}

output "instance_id" {
  description = "Instance ID of the Collector"
  value       = google_compute_instance.col.instance_id
}

output "self_link" {
  description = "Self link of the Collector instance"
  value       = google_compute_instance.col.self_link
}

output "zone" {
  description = "Zone of the Collector"
  value       = google_compute_instance.col.zone
}

output "service_account_email" {
  description = "Service account email for the Collector"
  value       = google_service_account.col_sa.email
}

output "web_ui_url" {
  description = "URL for the Guardium Web UI (via bastion port forwarding)"
  value       = "https://${google_compute_instance.col.network_interface[0].network_ip}:8443"
}

output "ssh_command" {
  description = "SSH command to connect to Collector (via bastion)"
  value       = "ssh cli@${google_compute_instance.col.network_interface[0].network_ip}"
}

output "logs_directory" {
  description = "Path to the logs directory for this Collector deployment"
  value       = "${path.module}/logs"
}

