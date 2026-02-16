# Create bastion host for GCP

## Introduction

This module creates a bastion host on GCP.

## Parameters

All parameters must be modified in the terraform.tfvars file. See the [documentation](../../examples/phase0bastion/README.md) in the example for instructions.

### GCP-related: Required to change

| Name | Comment | 
| --- | --- | 
| project_id | ID of the GCP project the machines will be part of |
| region | GCP region |
| zone | GCP zone |
| credentials_file | If you have changed the name of key.json, change it here as well. |
| network_name | Network for the machines |
| subnet_name | Subnet |
| subnet_cidr | IP of the subnet |
| firewall_name | Firewall settings for this network |
| bastion_name | Name of the bastion host to be created |
| bastion_machine_type | Hardware profile of the machine |
| bastion_private_ip | Set the IP of the bastion host in the network |
| management_subnet_name | The management subnet |
| management_subnet_cidr | IP of the management subnet |
| allowed_source_ips | IPs that will be able to SSH into the bastion host |
| admin_username | The `username` you created in step 1 |
| ssh_public_key | The public key you created in step 1 |
| ssh_private_key | The private key you created in step 1 |
