# PFE DevOps - AWS Infrastructure

Terraform code to provision AWS infrastructure for the PFE project.

## File Descriptions

- **`.gitignore`** - Files Git should ignore (state files, logs, temp files)
- **`.terraform.lock.hcl`** - Locks provider versions for reproducible deployments
- **`main.tf`** - Main Terraform configuration
- **`providers.tf`** - AWS provider configuration with region settings and default tags
- **`variables.tf`** - Variable declarations for AWS resources
- **`outputs.tf`** - Output values for provisioned resources

## Documentation

- [REQUIREMENTS.md](./REQUIREMENTS.md) - Detailed provider versions, module information, resources, inputs, and outputs
