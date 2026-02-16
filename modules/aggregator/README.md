# Create GDP Aggregator for GCP

## Introduction

This module creates a GDP Aggregator on GCP.

## Parameters

All parameters must be modified in the terraform.tfvars and aggregator_config.json files. See the [documentation](../../examples/phase2agg/README.md) in the example for instructions.

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
| terraform.tfvars | guardium_aggregator_image_id | Image file for the aggregator |
| terraform.tfvars | guardium_machine_type | Hardware profile for the machine |
| aggregator_config.json | vm_name | Name of the aggregator machine |
| aggregator_config.json | system_hostname | Same as previous |
| aggregator_config.json | instance_type | GCP instance type |
| aggregator_config.json | network_interface_ip | IP address that this machine will use |
| aggregator_config.json | system_domain | Domain for the machine |
| aggregator_config.json | guardium_final_pw | The CLI password that will be used. Set this according to the CLI requirements. |
| aggregator_config.json | guardium_shared_secret | The GDP shared secret for registering managed units |
| aggregator_config.json | guardium_central_manager_ip | IP address of the central manager |
| aggregator_config.json | guardium_license_key | Base GDP license key |
