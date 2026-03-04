variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"   
}

variable "vpc_name" {
  type    = string
  default = "todo-vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]   # adjust to your region
}

variable "public_subnets_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "private_subnets_cidrs" {
  type    = list(string)
  default = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "enable_dns_hostnames" { default = true }
variable "enable_dns_support"   { default = true }

variable "project_name" {
  type    = string
  default = "todo-app"
}

variable "environment" {
  type    = string
  default = "dev"   
}