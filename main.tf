terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.30"
    }
  }

  required_version = ">= 1.1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.private_subnets_cidrs
  public_subnets  = var.public_subnets_cidrs

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name = var.vpc_name
  }
}