# PFE DevOps - AWS Infrastructure

Terraform code to provision AWS infrastructure for the PFE project.

## File Descriptions

- **`.gitignore`** - Files Git should ignore (state files, logs, temp files)
- **`.terraform.lock.hcl`** - Locks provider versions for reproducible deployments
- **`main.tf`** - Terraform configuration and required providers
- **`providers.tf`** - AWS provider configuration with region settings
- **`variables.tf`** - Variable declarations (AWS region, VPC CIDR, VPC name)
- **`outputs.tf`** - Output values displayed after successful apply
- **`vpc.tf`** - AWS VPC resource definition

## Documentation

See [Requirements Documentation](./REQUIREMENTS.md) for detailed provider versions, resources, inputs, and outputs.

For more information about **Terraform-docs cli**, refer to the official [Terraform CLI Documentation](https://terraform-docs.io/user-guide/introduction/).