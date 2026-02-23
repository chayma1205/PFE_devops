#########
# VPC
#########

variable "aws_region" {
  type        = string
  description = "The region for the provisioned aws infra"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC cidr block"
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  type        = string
  description = "the name of your vpc"
  default     = "my-vpc"
}

variable "vpc_azs" {
  type        = list(string)
  description = "the availability zones of subnets within the vpc"
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "enable or desable dns hostnames withing a vpc"
  default     = true
}

variable "enable_dns_support" {
  type        = bool
  description = "enable or desable dns support withing a vpc"
  default     = true
}

variable "private_subnets_cidrs" {
  type        = list(string)
  description = "the list of cidr blocks for the private subnets"
  default     = []
}

variable "public_subnets_cidrs" {
  type        = list(string)
  description = "the list of cidr blocks for the public subnets"
  default     = []
}

#########
# BASTION INSTANCE  
#########
variable "bastion_ami" {
  type        = string
  description = "The id of ami to use for the bastion isntance"
}

variable "bastion_name" {
  type        = string
  description = ""
  default     = "bastion_instance"
}

variable "bastion_type" {
  type        = string
  description = "Bastion instance type"
}

variable "enable_bastion_monitoring" {
  type        = bool
  description = "Enable/desable bastion instance monitoring"
  default     = true
}

variable "bastion_ingress_rule_cidr" {
  type        = string
  description = "The cidr block of baction security group ingress rule"
  default     = "0.0.0.0/0"
}

variable "pub_key_name" {
  type        = string
  description = "The name of public ssh key to copy to your bastion instance and private ec2 instances and allow ssh access to them with your private key"
}

variable "prv_key_name" {
  type        = string
  description = "The name of private ssh key to copy to your bastion instance so it can ssh into the private ec2 instances"
}

variable "bastion_user_data" {
  type        = string
  description = "the .sh file for the user data"
  default     = null
}

variable "bastion_storage_size" {
  type        = number
  description = "The storage to allocate in Gb for the bastion instance"
  default     = 30
}

variable "bastion_allowed_db_port" {
  type        = number
  description = "The port of database service hosted in the bastion instance"
}

#########
# ALB
#########
variable "ecs_frontend_tasks_port" {
  type        = number
  description = "The port of ecs frontend tasks"
}

variable "ecs_backend_tasks_port" {
  type        = number
  description = "The port of ecs backend tasks"
}

#########
# ASG
#########

variable "asg_name" {
  type        = string
  description = "ASG name"
}

variable "asg_min_size" {
  type        = number
  description = "Minimum instances"
}

variable "asg_max_size" {
  type        = number
  description = "Maximum instances"
}

variable "asg_desired_capacity" {
  type        = number
  description = "Desired instances"
}

variable "asg_launch_template_name" {
  type        = string
  description = "name of the launch template"
}

variable "asg_launch_template_description" {
  type        = string
  description = "description for the launch template"
}

variable "asg_image_id" {
  type        = string
  description = "ami id to use for the instances"
}

variable "asg_instance_type" {
  type        = string
  description = "ec2 instance type"
}

#########
# ECS
#########

variable "cluster_name" {
  type        = string
  description = "ecs cluster name"
}

variable "frontend_task_definition_cpu" {
  type        = number
  description = "the vcpu to reserve for the frontend task definition"
}

variable "frontend_task_definition_memory" {
  type        = number
  description = "the memory to reserve for the frontend task definition"
}

variable "frontend_service_desired_tasks" {
  type        = number
  description = "the desired tasks number for frontend tasks"
}

variable "frontend_task_api_url" {
  description = "Backend API URL for the frontend application"
  type        = string
  default     = "" # it's set automatically
}

variable "backend_task_definition_cpu" {
  type        = number
  description = "the vcpu to reserve for the backend task definition"
}

variable "backend_task_definition_memory" {
  type        = number
  description = "the memory to reserve for the backend task definition"
}

variable "backend_service_desired_tasks" {
  type        = number
  description = "the desired tasks number for backend tasks"
}

variable "backend_task_db_user" {
  description = "Database username for the backend application"
  type        = string
}

variable "backend_task_db_password" {
  description = "Database password for the backend application"
  type        = string
}

variable "backend_task_db_port" {
  description = "Database port number"
  type        = number
}

variable "backend_task_db_name" {
  description = "Database name for the backend application"
  type        = string
}

variable "backend_task_db_host" {
  description = "Database host IP address or hostname"
  type        = string
  default     = null
}