# PFE DevOps - AWS Infrastructure

Terraform code to provision AWS infrastructure for the PFE project.

## File Descriptions

**folder : project/**
- **`.gitignore`** - Files Git should ignore (state files, logs, temp files)
- **`.terraform.lock.hcl`** - Locks provider versions for reproducible deployments
- **`main.tf`** - Main Terraform resources configuration
- **`terraform.tf`** - Terraform and backend configurations
- **`providers.tf`** - Providers configurations
- **`variables.tf`** - Variable declarations for AWS resources
- **`outputs.tf`** - Output values for provisioned resources

## ⚠️ Prerequisites: SSH Key Pair

Before running `terraform plan` or `terraform apply`, you **must** generate an SSH key pair. The Bastion instance uses this key to authenticate you, and the script automatically injects the private key into the Bastion to allow jumping to private instances.

### Generate Keys (Linux/Mac/Git Bash)
Run the following commands in your project root:

```bash
# Generate a new RSA 4096-bit key pair
ssh-keygen -t rsa -b 4096 -f key.pem

# Ensure permissions are restricted on your local machine
chmod 400 key.pem

# Generate the public key file (if not created automatically)
ssh-keygen -y -f key.pem > key.pub

## Deployment Instructions

1. Configure 'pub_key_name' and 'prv_key_name' variables to reference your new ssh keys
2. Initialize Terraform: `terraform init`
3. Review plan: `terraform plan`
4. Apply configuration: `terraform apply`
```

## Documentation

- [REQUIREMENTS.md](./REQUIREMENTS.md) - Detailed provider versions, module information, resources, inputs, and outputs
- [Remote Backend Init docs](./remote_backend_init/readme.md) - Detailed remote backend Initialization
