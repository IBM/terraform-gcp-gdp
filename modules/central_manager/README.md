# Create GDP Central Manager for GCP

## Introduction

This module creates a GDP Central Manager on GCP.

## Parameters

All parameters must be modified in the terraform.tfvars and central_manager_config.json files. See the [documentation](../../examples/phase1cm/README.md) in the example for instructions.

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
| terraform.tfvars | guardium_aggregator_image_id | Image file for the central manager |
| terraform.tfvars | guardium_machine_type | Hardware profile for the machine |
| central_manager_config.json | vm_name | Name of the central manager machine |
| central_manager_config.json | system_hostname | Same as previous |
| central_manager_config.json | instance_type | GCP instance type |
| central_manager_config.json | network_interface_ip | IP address that this machine will use |
| central_manager_config.json | system_domain | Domain for the machine |
| central_manager_config.json | guardium_final_pw | The CLI password that will be used. Set this according to the CLI requirements. |
| central_manager_config.json | guardium_shared_secret | The GDP shared secret for registering managed units |
| central_manager_config.json | guardium_central_manager_ip | Same as network_interface_ip |
| central_manager_config.json | guardium_license_key | Base GDP license key |

## Manual steps

After the Terraform process runs, it will create a stand-alone Aggregator. This must be manually converted to a Central Manager. See the [documentation](../../examples/phase1cm/README.md) in the example for instructions.
