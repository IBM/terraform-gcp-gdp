# Create GDP Central Manager for GCP

## Introduction

Use this example to create a GDP Central Manager on GCP.

## Summary of process

1. Configure the Terraform process.
2. Run the Terraform process. This will create an Aggregator that can be converted to a Central Manager.
3. Manually store and accept the GDP license, and convert the Aggregator to a Central Manager.

## 0. Before you begin

If you followed all the steps in creating the bastion host, you are now able to SSH into it.

Connect to the bastion host using a command like this.

```
ssh -i [SSH-private-key-file] [username]@[bastion-public-IP]
```

Here:
* `[SSH-private-key-file]` is the SSH key you created in the bastion host process and added to GCP.
* `[username]` is the username you specified when you created the SSH key.
* `[bastion-public-IP]` is the public IP address of the bastion host. You can see it in the GCP console and it will also be printed to the terminal at the end of the Terraform process.

The bastion host contains the complete Terraform scripts and all the requirements for running them.

Go to the central_manager directory of your Terraform scripts.

```
cd /opt/guardium_gcp/examples/phase1cm/
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
| guardium_aggregator_image_id | Image file for the central manager |
| guardium_machine_type | Hardware profile for the machine |

After you have verified the parameters, save the file and exit the editor.

Edit the file `central_manager_config.json` and enter the parameters for your installation.

```
vi central_manager_config.json
```

| Name | Comment |
| ---- | ------- |
| vm_name | Name of the central manager machine |
| system_hostname | Same as previous |
| instance_type | GCP instance type |
| network_interface_ip | IP address that this machine will use |
| system_domain | Domain for the machine |
| guardium_final_pw | The CLI password that will be used. Set this according to the CLI requirements. |
| guardium_shared_secret | The GDP shared secret for registering managed units |
| guardium_central_manager_ip | Same as network_interface_ip |
| guardium_license_key | Base GDP license key |

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

## 3. Connect to GDP

Disconnect your SSH session to the bastion host, and reconnect with port forwarding.

```
ssh -i [SSH-private-key-file] -L 8443:[cm-ip]:8443 [username]@[bastion-public-ip]
```

Here:
* `[SSH-private-key-file]` is the SSH key you created in the bastion host process and added to GCP.
* `[cm-ip]` is the IP address of the CM that you specified above.
* `[username]` is the username you specified when you created the SSH key.
* `[bastion-public-IP]` is the public IP address of the bastion host.

Connect to GDP via a browser with a URL like this:

```
https://ip-address:8443
```

You can then begin using GDP. In the login screen:
* User: `admin` 
* Password: `guardium` 

You will be prompted to immediately change the password.

Go to the License screen and accept the base license. Then you can add and accept any other licenses you have.

## 4. Convert to Central Manager

In the bastion SSH session, go to the central manager modules directory.

```
cd ./modules/central_manager
```

Run the script to convert the GDP appliance from Aggregator to Central Manager.

```
./run_guardium_phase2.sh [cm-ip] '[cli-password]' [shared-secret]
```

Here:
* `[cm-ip]` is the IP address of the CM that you specified above.
* `[cli-password]` is the password you specified for CLI above.
* `[shared-secret]` is the shared secret you specified above.
