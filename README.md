# PFE DevOps - AWS Infrastructure

Terraform code to provision AWS infrastructure for the PFE project.

## File Descriptions

- **`.gitignore`** - Files Git should ignore (state files, logs, temp files)
- **`.terraform.lock.hcl`** - Locks provider versions for reproducible deployments
- **`main.tf`** - Main Terraform configuration
- **`providers.tf`** - AWS provider configuration with region settings and default tags
- **`variables.tf`** - Variable declarations for AWS resources
- **`outputs.tf`** - Output values for provisioned resources

## Deployment Instructions

1. Configure variables in `dev.auto.tfvars` or provide via command line
2. Initialize Terraform: `terraform init`
3. Review plan: `terraform plan`
4. Apply configuration: `terraform apply`
5. Access resources using the output values

## Documentation

- [REQUIREMENTS.md](./REQUIREMENTS.md) - Detailed provider versions, module information, resources, inputs, and outputs
