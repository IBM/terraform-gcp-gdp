# Create GDP Collector for GCP

## Introduction

This module creates a GDP Collector on GCP.

## Parameters

All parameters must be modified in the terraform.tfvars and collector_config.json files. See the [documentation](../../examples/phase3col/README.md) in the example for instructions.

### GCP-related: Required to change

| File | Name | Comment | 
| --- | --- | --- | 
| terraform.tfvars | project_id | ID of the GCP project the machines will be part of |
| terraform.tfvars | region | GCP region |
| terraform.tfvars | zone | GCP zone |
| terraform.tfvars | credentials_file | If you have changed the name of key.json, change it here as well. |
| terraform.tfvars | network_name | Network for the machines |
| terraform.tfvars | subnet_name | Subnet |
| terraform.tfvars | subnet_cidr | IP of the subnet |
| terraform.tfvars | guardium_collector_image_id | Image file for the collector |
| terraform.tfvars | guardium_machine_type | Hardware profile for the machine |
| collector_config.json | vm_name | Name of the collector machine |
| collector_config.json | system_hostname | Same as previous |
| collector_config.json | instance_type | GCP instance type |
| collector_config.json | network_interface_ip | IP address that this machine will use |
| collector_config.json | system_domain | Domain for the machine |
| collector_config.json | guardium_final_pw | The CLI password that will be used. Set this according to the CLI requirements. |
| collector_config.json | guardium_shared_secret | The GDP shared secret for registering managed units |
| collector_config.json | guardium_central_manager_ip | IP address of the central manager |
| collector_config.json | guardium_license_key | Base GDP license key |
