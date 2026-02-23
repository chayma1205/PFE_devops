# Remote Backend Initialization

This directory contains Terraform configuration for setting up the remote backend infrastructure required for state management.

## Purpose

This Terraform configuration creates the necessary AWS resources for remote state storage and locking:
- S3 bucket for storing Terraform state files
- DynamoDB table for state locking to prevent concurrent operations

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.1 |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | ~> 6.30 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider_aws) | 6.30.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_remote_state_bucket"></a> [remote_state_bucket](#module_remote_state_bucket) | terraform-aws-modules/s3-bucket/aws | 5.10.0 |
| <a name="module_remote_state_locking"></a> [remote_state_locking](#module_remote_state_locking) | terraform-aws-modules/dynamodb-table/aws | 5.5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_state_bucket_name"></a> [state_bucket_name](#input_state_bucket_name) | The remote state S3 bucket name, must be globally unique | `string` | n/a | yes |
| <a name="input_dynamodb_table_name"></a> [dynamodb_table_name](#input_dynamodb_table_name) | The name of dynamoDB table to hold the state locking | `string` | `"state_lock"` | no |


## Usage

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Set variables**:
   Create a `terraform.auto.tfvars` file or use environment variables:
   ```hcl
   state_bucket_name = "your-unique-bucket-name"
   dynamodb_table_name = "state_lock"
   ```

3. **Plan and Apply**:
   ```bash
   terraform plan
   terraform apply
   ```

## Important Notes

- The S3 bucket name must be globally unique across all of AWS
- Once created, the bucket has `force_destroy = false` to prevent accidental deletion
- DynamoDB table has deletion protection enabled
- The created resources will be used by the main Terraform configuration for remote state management
- After successful creation, update the main Terraform configuration's backend settings to use these resources
