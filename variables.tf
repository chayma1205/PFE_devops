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
  default     = "pfe_vpc"
}

variable "igw_name" {
  type        = string
  description = "the name of your igw"
  default     = "my_igw"
}

variable "route_table_name" {
  type        = string
  description = "the name of your route tabe"
  default     = "public_rt"
}

variable "public_subnet_1_az" {
  type        = string
  description = "subnet az"
  default     = "us-east-1a"
}

variable "public_subnet_1_cidr" {
  type        = string
  description = "public subnet cidr block"
  default     = "10.0.1.0/24"
}

variable "public_subnet_1_name" {
  type        = string
  description = "public subnet name"
  default     = "public_1"
}