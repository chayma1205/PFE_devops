## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.30 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.30.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module_vpc) | terraform-aws-modules/vpc/aws | ~> 6.6 |


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **AWS Settings** |||||
| <a name="input_aws_region"></a> [aws_region](#input_aws_region) | AWS region for provisioned infrastructure | `string` | `"us-east-1"` | no |
| **VPC Configuration** |||||
| <a name="input_vpc_name"></a> [vpc_name](#input_vpc_name) | The name of your VPC | `string` | `"my-vpc"` | no |
| <a name="input_vpc_cidr"></a> [vpc_cidr](#input_vpc_cidr) | VPC CIDR block | `string` | `"10.0.0.0/16"` | no |
| <a name="input_enable_dns_hostnames"></a> [enable_dns_hostnames](#input_enable_dns_hostnames) | Enable DNS hostnames in the VPC | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable_dns_support](#input_enable_dns_support) | Enable DNS resolution in the VPC | `bool` | `true` | no |
| <a name="input_vpc_azs"></a> [vpc_azs](#input_vpc_azs) | Availability zones for subnets within the VPC | `list(string)` | n/a | yes |
| **Subnet Configuration** |||||
| <a name="input_public_subnets_cidrs"></a> [public_subnets_cidrs](#input_public_subnets_cidrs) | CIDR blocks for public subnets (one per AZ) | `list(string)` | `[]` | no |
| <a name="input_private_subnets_cidrs"></a> [private_subnets_cidrs](#input_private_subnets_cidrs) | CIDR blocks for private subnets (one per AZ) | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vpc_id"></a> [vpc_id](#output_vpc_id) | the id of the VPC |
| <a name="output_vpc_cidr_block"></a> [vpc_cidr_block](#output_vpc_cidr_block) | the cidr block of the VPC |
| <a name="output_public_subnet_ids"></a> [public_subnet_ids](#output_public_subnet_ids) | List of ids of public subnets |
| <a name="output_private_subnet_ids"></a> [private_subnet_ids](#output_private_subnet_ids) | List of ids of private subnets |
| <a name="output_public_route_table_ids"></a> [public_route_table_ids](#output_public_route_table_ids) | List of ids of public route tables |
| <a name="output_private_route_table_ids"></a> [private_route_table_ids](#output_private_route_table_ids) | List of ids of private route tables |
| <a name="output_igw_id"></a> [igw_id](#output_igw_id) | the id of the Internet Gateway |
