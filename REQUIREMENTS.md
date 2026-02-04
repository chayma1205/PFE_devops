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

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.public_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The region for the provisioned aws infra | `string` | `"us-east-1"` | no |
| <a name="input_igw_name"></a> [igw\_name](#input\_igw\_name) | the name of your igw | `string` | `"my_igw"` | no |
| <a name="input_public_subnet_1_az"></a> [public\_subnet\_1\_az](#input\_public\_subnet\_1\_az) | subnet az | `string` | `"us-east-1a"` | no |
| <a name="input_public_subnet_1_cidr"></a> [public\_subnet\_1\_cidr](#input\_public\_subnet\_1\_cidr) | public subnet cidr block | `string` | `"10.0.1.0/24"` | no |
| <a name="input_public_subnet_1_name"></a> [public\_subnet\_1\_name](#input\_public\_subnet\_1\_name) | public subnet name | `string` | `"public_1"` | no |
| <a name="input_route_table_name"></a> [route\_table\_name](#input\_route\_table\_name) | the name of your route tabe | `string` | `"public_rt"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC cidr block | `string` | `"10.0.0.0/16"` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | the name of your vpc | `string` | `"pfe_vpc"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_public_subnet_1_cidr"></a> [public\_subnet\_1\_cidr](#output\_public\_subnet\_1\_cidr) | cidr block of the public subnet |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | the cidr block of the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | the id of the VPC |
