## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.1 |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | ~> 6.30 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider_aws) | 6.30.0 |

> **Note**: See [remote_backend_init/README.md](./remote_backend_init/README.md) for backend infrastructure documentation.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module_vpc) | terraform-aws-modules/vpc/aws | ~> 6.6 |
| <a name="module_bastion_instance"></a> [bastion_instance](#module_bastion_instance) | terraform-aws-modules/ec2-instance/aws | 6.2.0 |
| <a name="module_front_alb"></a> [front_alb](#module_front_alb) | terraform-aws-modules/alb/aws | 10.5.0 |
| <a name="module_back_alb"></a> [back_alb](#module_back_alb) | terraform-aws-modules/alb/aws | 10.5.0 |
| <a name="module_web_asg"></a> [web_asg](#module_web_asg) | terraform-aws-modules/autoscaling/aws | n/a |
| <a name="module_ecs"></a> [ecs](#module_ecs) | terraform-aws-modules/ecs/aws | n/a |
| <a name="module_db_rds"></a> [db_rds](#module_db_rds) | terraform-aws-modules/rds/aws | 7.1.0 |
| <a name="module_db_rds_sg"></a> [db_rds_sg](#module_db_rds_sg) | terraform-aws-modules/security-group/aws | 5.3.1 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecs_task_execution_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_key_pair.bastion_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_security_group.ecs_instance_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Files

| Name | Description |
|------|-------------|
| [init_bastion.sh](./project/init_bastion.sh) | Bash script used as user data for the bastion instance. Sets up SSH keys, installs Docker, clones the todo_app repository, and starts the database container. Also installs AWS CLI. You can add custom instruction in this file

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
| <a name="input_pub_key_name"></a> [pub_key_name](#input_pub_key_name) | The name of public SSH key to copy to your bastion instance and private EC2 instances and allow SSH access to them with your private key | `string` | n/a | yes |
| <a name="input_prv_key_name"></a> [prv_key_name](#input_prv_key_name) | The name of private SSH key to copy to your bastion instance so it can SSH into the private EC2 instances | `string` | n/a | yes |
| <a name="input_bastion_storage_size"></a> [bastion_storage_size](#input_bastion_storage_size) | The storage to allocate in GB for the bastion instance | `number` | `30` | no |
| <a name="input_bastion_allowed_db_port"></a> [bastion_allowed_db_port](#input_bastion_allowed_db_port) | The port of database service hosted in the bastion instance | `number` | n/a | yes |

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
| <a name="input_frontend_task_definition_cpu"></a> [frontend_task_definition_cpu](#input_frontend_task_definition_cpu) | The vCPU to reserve for the frontend task definition | `number` | n/a | yes |
| <a name="input_frontend_task_definition_memory"></a> [frontend_task_definition_memory](#input_frontend_task_definition_memory) | The memory to reserve for the frontend task definition | `number` | n/a | yes |
| <a name="input_frontend_service_desired_tasks"></a> [frontend_service_desired_tasks](#input_frontend_service_desired_tasks) | The desired tasks number for frontend tasks | `number` | n/a | yes |
| <a name="input_frontend_task_api_url"></a> [frontend_task_api_url](#input_frontend_task_api_url) | Backend API URL for the frontend application | `string` | `""` | no |
| <a name="input_backend_task_definition_cpu"></a> [backend_task_definition_cpu](#input_backend_task_definition_cpu) | The vCPU to reserve for the backend task definition | `number` | n/a | yes |
| <a name="input_backend_task_definition_memory"></a> [backend_task_definition_memory](#input_backend_task_definition_memory) | The memory to reserve for the backend task definition | `number` | n/a | yes |
| <a name="input_backend_service_desired_tasks"></a> [backend_service_desired_tasks](#input_backend_service_desired_tasks) | The desired tasks number for backend tasks | `number` | n/a | yes |
| <a name="input_backend_task_db_user"></a> [backend_task_db_user](#input_backend_task_db_user) | Database username for the backend application | `string` | n/a | yes |
| <a name="input_backend_task_db_password"></a> [backend_task_db_password](#input_backend_task_db_password) | Database password for the backend application | `string` | n/a | yes |
| <a name="input_backend_task_db_port"></a> [backend_task_db_port](#input_backend_task_db_port) | Database port number | `number` | n/a | yes |
| <a name="input_backend_task_db_name"></a> [backend_task_db_name](#input_backend_task_db_name) | Database name for the backend application | `string` | n/a | yes |


##### RDS Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_rds_instance_name"></a> [rds_instance_name](#input_rds_instance_name) | The name of the RDS instance | `string` | `"app_db"` | no |
| <a name="input_rds_engine"></a> [rds_engine](#input_rds_engine) | The database engine to use | `string` | `"postgres"` | no |
| <a name="input_rds_engine_version"></a> [rds_engine_version](#input_rds_engine_version) | The engine version to use | `string` | `"17"` | no |
| <a name="input_rds_instance_class"></a> [rds_instance_class](#input_rds_instance_class) | The instance type of the RDS instance | `string` | `"db.t4g.small"` | no |
| <a name="input_rds_db_name"></a> [rds_db_name](#input_rds_db_name) | The DB name to create. If omitted, no database is created initially | `string` | n/a | yes |
| <a name="input_rds_db_username"></a> [rds_db_username](#input_rds_db_username) | Username for the master DB user | `string` | `"master"` | no |
| <a name="input_rds_db_port"></a> [rds_db_port](#input_rds_db_port) | The port on which the DB accepts connections | `string` | `"5432"` | no |
| <a name="input_rds_db_allocated_storage"></a> [rds_db_allocated_storage](#input_rds_db_allocated_storage) | The allocated storage in gigabytes, must be >= 20 | `number` | `20` | no |
| <a name="input_rds_db_max_allocated_storage"></a> [rds_db_max_allocated_storage](#input_rds_db_max_allocated_storage) | Specifies the value for Storage Autoscaling | `number` | `100` | no |
| <a name="input_rds_multi_az"></a> [rds_multi_az](#input_rds_multi_az) | Specifies if the RDS instance is multi-AZ | `bool` | `false` | no |
| <a name="input_rds_subnet_group_name"></a> [rds_subnet_group_name](#input_rds_subnet_group_name) | Name of DB subnet group. DB instance will be created in the VPC associated with the DB subnet group. If unspecified, will be created in the default VPC | `string` | `"my-subnet-group"` | no |

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
| <a name="output_front_alb_dns"></a> [front_alb_dns](#output_front_alb_dns) | The DNS name of the frontend ALB |
| <a name="output_back_alb_dns"></a> [back_alb_dns](#output_back_alb_dns) | The DNS name of the backend ALB |

##### ECS Outputs
| Name | Description |
|------|-------------|
| <a name="output_ecs_cluster_name"></a> [ecs_cluster_name](#output_ecs_cluster_name) | ECS cluster name |
| <a name="output_ecs_cluster_arn"></a> [ecs_cluster_arn](#output_ecs_cluster_arn) | ECS cluster ARN |

##### RDS Outputs
| Name | Description |
|------|-------------|
| <a name="output_rds_endpoint"></a> [rds_endpoint](#output_rds_endpoint) | RDS instance endpoint (includes port) |
| <a name="output_rds_address"></a> [rds_address](#output_rds_address) | RDS instance address (hostname only, no port) |
| <a name="output_rds_port"></a> [rds_port](#output_rds_port) | RDS instance port |
| <a name="output_rds_database_name"></a> [rds_database_name](#output_rds_database_name) | Name of the database |
| <a name="output_rds_username"></a> [rds_username](#output_rds_username) | Master username for the database (sensitive) |
| <a name="output_rds_instance_id"></a> [rds_instance_id](#output_rds_instance_id) | RDS instance ID |
