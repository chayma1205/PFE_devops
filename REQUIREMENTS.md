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
| <a name="module_vpc"></a> [vpc](#module_vpc) | terraform-aws-modules/vpc/aws | ~> 6.6 |
| <a name="module_bastion_instance"></a> [bastion_instance](#module_bastion_instance) | terraform-aws-modules/ec2-instance/aws | 6.2.0 |
| <a name="module_front_alb"></a> [front_alb](#module_front_alb) | terraform-aws-modules/alb/aws | 10.5.0 |
| <a name="module_back_alb"></a> [back_alb](#module_back_alb) | terraform-aws-modules/alb/aws | 10.5.0 |
| <a name="module_web_asg"></a> [web_asg](#module_web_asg) | terraform-aws-modules/autoscaling/aws | n/a |
| <a name="module_ecs_1"></a> [ecs_1](#module_ecs_1) | terraform-aws-modules/ecs/aws | n/a |


## Inputs

##### AWS Settings
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws_region](#input_aws_region) | The region for the provisioned AWS infrastructure | `string` | `"us-east-1"` | no |

##### VPC Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_vpc_name"></a> [vpc_name](#input_vpc_name) | The name of your VPC | `string` | `"my-vpc"` | no |
| <a name="input_vpc_cidr"></a> [vpc_cidr](#input_vpc_cidr) | VPC CIDR block | `string` | `"10.0.0.0/16"` | no |
| <a name="input_vpc_azs"></a> [vpc_azs](#input_vpc_azs) | The availability zones of subnets within the VPC | `list(string)` | n/a | yes |
| <a name="input_enable_dns_hostnames"></a> [enable_dns_hostnames](#input_enable_dns_hostnames) | Enable or disable DNS hostnames within a VPC | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable_dns_support](#input_enable_dns_support) | Enable or disable DNS support within a VPC | `bool` | `true` | no |

##### Subnet Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_public_subnets_cidrs"></a> [public_subnets_cidrs](#input_public_subnets_cidrs) | The list of CIDR blocks for the public subnets | `list(string)` | `[]` | no |
| <a name="input_private_subnets_cidrs"></a> [private_subnets_cidrs](#input_private_subnets_cidrs) | The list of CIDR blocks for the private subnets | `list(string)` | `[]` | no |

##### Bastion Instance Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_ami"></a> [bastion_ami](#input_bastion_ami) | The ID of AMI to use for the bastion instance | `string` | n/a | yes |
| <a name="input_bastion_name"></a> [bastion_name](#input_bastion_name) | Name of the bastion instance | `string` | `"bastion_instance"` | no |
| <a name="input_bastion_type"></a> [bastion_type](#input_bastion_type) | Bastion instance type | `string` | n/a | yes |
| <a name="input_enable_bastion_monitoring"></a> [enable_bastion_monitoring](#input_enable_bastion_monitoring) | Enable/disable bastion instance monitoring | `bool` | `true` | no |
| <a name="input_bastion_ingress_rule_cidr"></a> [bastion_ingress_rule_cidr](#input_bastion_ingress_rule_cidr) | The CIDR block of bastion security group ingress rule | `string` | `"0.0.0.0/0"` | no |
| <a name="input_bastion_key_name"></a> [bastion_key_name](#input_bastion_key_name) | The name of SSH key to access your bastion instance | `string` | n/a | yes |
| <a name="input_bastion_user_data"></a> [bastion_user_data](#input_bastion_user_data) | The .sh file for the user data | `string` | `null` | no |
| <a name="input_bastion_storage_size"></a> [bastion_storage_size](#input_bastion_storage_size) | The storage to allocate in GB for the bastion instance | `number` | `30` | no |

##### Application Load Balancer Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ecs_frontend_tasks_port"></a> [ecs_frontend_tasks_port](#input_ecs_frontend_tasks_port) | The port of ECS frontend tasks | `number` | n/a | yes |
| <a name="input_ecs_backend_tasks_port"></a> [ecs_backend_tasks_port](#input_ecs_backend_tasks_port) | The port of ECS backend tasks | `number` | n/a | yes |

##### Auto Scaling Group Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_asg_name"></a> [asg_name](#input_asg_name) | ASG name | `string` | n/a | yes |
| <a name="input_asg_min_size"></a> [asg_min_size](#input_asg_min_size) | Minimum instances | `number` | n/a | yes |
| <a name="input_asg_max_size"></a> [asg_max_size](#input_asg_max_size) | Maximum instances | `number` | n/a | yes |
| <a name="input_asg_desired_capacity"></a> [asg_desired_capacity](#input_asg_desired_capacity) | Desired instances | `number` | n/a | yes |
| <a name="input_asg_launch_template_name"></a> [asg_launch_template_name](#input_asg_launch_template_name) | Name of the launch template | `string` | n/a | yes |
| <a name="input_asg_launch_template_description"></a> [asg_launch_template_description](#input_asg_launch_template_description) | Description for the launch template | `string` | n/a | yes |
| <a name="input_asg_image_id"></a> [asg_image_id](#input_asg_image_id) | AMI ID to use for the instances | `string` | n/a | yes |
| <a name="input_asg_instance_type"></a> [asg_instance_type](#input_asg_instance_type) | EC2 instance type | `string` | n/a | yes |

##### ECS Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster_name](#input_cluster_name) | ECS cluster name | `string` | n/a | yes |

## Outputs

##### VPC Outputs
| Name | Description |
|------|-------------|
| <a name="output_vpc_id"></a> [vpc_id](#output_vpc_id) | ID of the VPC |
| <a name="output_public_subnet_ids"></a> [public_subnet_ids](#output_public_subnet_ids) | IDs of public subnets |
| <a name="output_private_subnet_ids"></a> [private_subnet_ids](#output_private_subnet_ids) | IDs of private subnets |

##### Bastion Instance Outputs
| Name | Description |
|------|-------------|
| <a name="output_bastion_public_ip"></a> [bastion_public_ip](#output_bastion_public_ip) | The public IP of bastion instance |

##### Auto Scaling Group Outputs
| Name | Description |
|------|-------------|
| <a name="output_asg_name"></a> [asg_name](#output_asg_name) | Autoscaling group name |
| <a name="output_asg_arn"></a> [asg_arn](#output_asg_arn) | Autoscaling group ARN |
| <a name="output_asg_id"></a> [asg_id](#output_asg_id) | Autoscaling group ID |
| <a name="output_launch_template_id"></a> [launch_template_id](#output_launch_template_id) | Launch template ID used by the autoscaling group |
| <a name="output_launch_template_latest_version"></a> [launch_template_latest_version](#output_launch_template_latest_version) | Latest launch template version |

##### Application Load Balancer Outputs
| Name | Description |
|------|-------------|
| <a name="output_front_alb_dns"></a> [front_alb_dns](#output_front_alb_dns) | The DNS of front ALB |
| <a name="output_back_alb_dns"></a> [back_alb_dns](#output_back_alb_dns) | The DNS of back ALB |

##### ECS Outputs
| Name | Description |
|------|-------------|
| <a name="output_ecs_cluster_name"></a> [ecs_cluster_name](#output_ecs_cluster_name) | ECS cluster name |
| <a name="output_ecs_cluster_arn"></a> [ecs_cluster_arn](#output_ecs_cluster_arn) | ECS cluster ARN |
