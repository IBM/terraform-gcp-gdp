# Create GDP Collector for GCP

## Introduction

Use this example to create a GDP Collector on GCP.

## Summary of process

1. Configure the Terraform process.
2. Run the Terraform process. This will create a Collector.

## 0. Before you begin

Follow the instructions in the [central manager README file](../phase1cm/README.md) to connect to the bastion host.

Go to the collector directory of your Terraform scripts.

```
cd /opt/guardium_gcp/examples/phase3col/
```

All further work will be done from here.

## 1. Edit the parameters

Create the file terraform.tfvars based on the example file.

```
cp terraform.tfvars.example terraform.tfvars
```

Edit the file and enter the parameters for your installation.

```
vi terraform.tfvars
```

| Name | Comment |
| ---- | ------- |
| project_id | ID of the GCP project the machines will be part of |
| region | GCP region |
| zone | GCP zone |
| credentials_file | If you have changed the name of key.json, change it here as well. |
| network_name | Network for the machines |
| subnet_name | Subnet |
| subnet_cidr | IP of the subnet |
| guardium_collector_image_id | Image file for the collector |
| guardium_machine_type | Hardware profile for the machine |

After you have verified the parameters, save the file and exit the editor.

Edit the file `collector_config.json` and enter the parameters for your installation.

```
vi collector_config.json
```

| Name | Comment |
| ---- | ------- |
| vm_name | Name of the collector machine |
| system_hostname | Same as previous |
| instance_type | GCP instance type |
| network_interface_ip | IP address that this machine will use |
| system_domain | Domain for the machine |
| guardium_final_pw | The CLI password that will be used. Set this according to the CLI requirements. |
| guardium_shared_secret | The GDP shared secret for registering managed units |
| guardium_central_manager_ip | IP address of the central manager |
| guardium_license_key | Empty string |

After you have verified the parameters, save the file and exit the editor.

## 2. Run the Terraform process

Start by initializing Terraform.

```
terraform init
```

Then set up Terraform to run the process you have defined.

```
terraform plan
```

Finally, run the process.

```
terraform apply
```

You will be prompted to enter "yes" after a few seconds. Then the process will run until it completes. This could take up to 45 minutes.
