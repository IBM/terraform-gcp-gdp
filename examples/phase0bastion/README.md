# Create bastion host for GCP

## Introduction

Use this example to create a bastion host on GCP which will be used afterwards to create all the GDP machines.

## Summary of process

1. Get needed prerequisites.
2. Configure the Terraform process.
3. Run the Terraform process. This will create a bastion host.
4. Verify connectivity.

## 1. Prerequisites

From your GCP administrator, obtain a `key.json` file that has an access key for creating instances on GCP.

Copy this file into each of the `examples` directories.

For example, if you have the `key.json` file in your home directory and you are in a shell in the root directory of the Terraform scripts, you would enter these commands:

```
cp ~/key.json ./examples/phase0bastion/
cp ~/key.json ./examples/phase1cm/
cp ~/key.json ./examples/phase2agg/
cp ~/key.json ./examples/phase3col/
```

Create an SSH key that you will use to access the bastion host and the GDP machines.

```
ssh-keygen -t rsa -b 4096 -C [username]
```

Choose a simple `[username]`. Later, you will put this in the configuration files so that the Terraform process can access the machines.

Go to the GCP Console and add your public SSH key to GCP. Be sure to use the same `[username]` when you do this.

## 2. Edit the parameters

Go into the `phase0bastion` directory.

```
cd ./examples/phase0bastion/
```

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

After you have verified the parameters, save the file and exit the editor.

## 3. Run the Terraform process

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

You will be prompted to enter "yes" after a few seconds. Then the process will run until it completes. This could take up to 10 minutes.

## 4. Connect to the bastion host

Check that you can SSH into the bastion host you just created.

```
ssh -i [SSH-private-key-file] [username]@[bastion-public-IP]
```

Here:
* `[SSH-private-key-file]` is the SSH key you created in step 1 and added to GCP.
* `[username]` is the username you specified when you created the SSH key.
* `[bastion-public-IP]` is the public IP address of the bastion host. You can see it in the GCP console and it will also be printed to the terminal at the end of the Terraform process.
