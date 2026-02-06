# AWS VPC Terraform Module

This Terraform module creates a complete AWS VPC infrastructure with public and private subnets, internet gateway, and optional NAT gateway.

## Features

- VPC with customizable CIDR block
- Public subnets with internet gateway
- Private subnets with optional NAT gateway
- Automatic DNS support and hostnames
- Flexible availability zone configuration
- Customizable resource tagging

## Usage

### Basic Example

```hcl
module "vpc" {
  source = "./path-to-module"

  name               = "my-project"
  cidr               = "10.0.0.0/16"
  azs                = ["us-east-1a", "us-east-1b"]
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway = true

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Without NAT Gateway

```hcl
module "vpc" {
  source = "./path-to-module"

  name               = "dev-vpc"
  cidr               = "172.16.0.0/16"
  azs                = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets     = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  private_subnets    = ["172.16.101.0/24", "172.16.102.0/24", "172.16.103.0/24"]
  enable_nat_gateway = false

  tags = {
    Environment = "development"
  }
}
```
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.1 |
| aws | ~> 6.30 |

## Resources Created

This module creates the following AWS resources:

| Resource | Type | Description |
|----------|------|-------------|
| VPC | `aws_vpc` | Main VPC with DNS support enabled |
| Internet Gateway | `aws_internet_gateway` | IGW attached to the VPC |
| Public Subnets | `aws_subnet` | Public subnets across specified AZs |
| Private Subnets | `aws_subnet` | Private subnets across specified AZs |
| Public Route Table | `aws_route_table` | Route table with route to IGW |
| Private Route Table | `aws_route_table` | Route table with optional route to NAT GW |
| Public Route Table Associations | `aws_route_table_association` | Associates public subnets with public route table |
| Private Route Table Associations | `aws_route_table_association` | Associates private subnets with private route table |
| Elastic IP | `aws_eip` | EIP for NAT gateway (if enabled) |
| NAT Gateway | `aws_nat_gateway` | NAT gateway in first public subnet (if enabled) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for the VPC resources | `string` | n/a | yes |
| cidr | The CIDR block for the VPC | `string` | n/a | yes |
| azs | Availability zones | `list(string)` | n/a | yes |
| public_subnets | Public subnets CIDR blocks | `list(string)` | n/a | yes |
| private_subnets | Private subnets CIDR blocks | `list(string)` | n/a | yes |
| enable_nat_gateway | Whether or not to enable NAT gateway | `bool` | `true` | no |
| tags | Tags to attach to VPC resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| public_subnet_ids | List of IDs of public subnets |
| private_subnet_ids | List of IDs of private subnets |
| public_rt_id | The ID of the public route table |
| private_rt_id | The ID of the private route table |
| igw_id | The ID of the Internet Gateway |

## Notes

- Public subnets have `map_public_ip_on_launch` enabled
- All resources are tagged with a `Name` tag using the format `{name}-vpc-{resource-type}`
- The NAT Gateway is deployed in the first public subnet when enabled
- A single NAT Gateway is used for all private subnets (cost optimization)
- DNS hostnames and DNS support are enabled by default