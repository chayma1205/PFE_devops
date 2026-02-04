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