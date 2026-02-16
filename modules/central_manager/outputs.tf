#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/central_manager/outputs.tf (GCP Version)

output "vm_name" {
  description = "Name of the Central Manager VM"
  value       = google_compute_instance.cm.name
}

output "private_ip" {
  description = "Private IP address of the Central Manager"
  value       = google_compute_instance.cm.network_interface[0].network_ip
}

output "instance_id" {
  description = "Instance ID of the Central Manager"
  value       = google_compute_instance.cm.instance_id
}

output "self_link" {
  description = "Self link of the Central Manager instance"
  value       = google_compute_instance.cm.self_link
}

output "zone" {
  description = "Zone of the Central Manager"
  value       = google_compute_instance.cm.zone
}

output "service_account_email" {
  description = "Service account email for the Central Manager"
  value       = google_service_account.cm_sa.email
}

output "web_ui_url" {
  description = "URL for the Guardium Web UI (via bastion port forwarding)"
  value       = "https://${google_compute_instance.cm.network_interface[0].network_ip}:8443"
}

output "ssh_command" {
  description = "SSH command to connect to Central Manager (via bastion)"
  value       = "ssh cli@${google_compute_instance.cm.network_interface[0].network_ip}"
}

output "logs_directory" {
  description = "Path to the logs directory for this Central Manager deployment"
  value       = "${path.module}/logs"
}

