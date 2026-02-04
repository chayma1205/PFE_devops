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

variable "vpc_azs" {
  type        = list(string)
  description = "the availability zones of subnets within the vpc"
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