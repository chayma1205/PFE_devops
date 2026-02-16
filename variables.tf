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
# ASG
#########

variable "asg_names" {
  type        = list(string)
  description = "list of asg names"
}

variable "asg_min_sizes" {
  type        = list(number)
  description = "list of minimum sizes for each auto scaling group"
}

variable "asg_max_sizes" {
  type        = list(number)
  description = "list of maximum sizes for each auto scaling group"
}

variable "asg_desired_capacities" {
  type        = list(number)
  description = "list of desired capacities for each auto scaling group"
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