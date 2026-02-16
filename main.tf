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

  public_subnet_suffix  = "pub"
  private_subnet_suffix = "prv"

  igw_tags = {
    Name = "${var.vpc_name}-igw"
  }

  public_route_table_tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  count = length(var.asg_names)

  name = var.asg_names[count.index]
  min_size = var.asg_min_sizes[count.index]
  max_size = var.asg_max_sizes[count.index]
  desired_capacity = var.asg_desired_capacities[count.index]
  vpc_zone_identifier = var.vpc_azs[*]
}