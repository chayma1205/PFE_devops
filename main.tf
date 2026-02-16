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
  source = "terraform-aws-modules/autoscaling/aws"



  count = length(var.asg_names)

  # Autoscaling group config
  name                = var.asg_names[count.index]
  min_size            = var.asg_min_sizes[count.index]
  max_size            = var.asg_max_sizes[count.index]
  desired_capacity    = var.asg_desired_capacities[count.index]
  vpc_zone_identifier = var.vpc_azs[*]

  # Launch template config
  launch_template_name        = var.asg_launch_template_name
  launch_template_description = var.asg_launch_template_description
  launch_template_id          = var.asg_image_id
  instance_type               = var.asg_instance_type
  enable_monitoring           = true

  # IAM role config
  # IAM instance profile is required to grant EC2 instances the necessary permissions to:
  # - Register with the ECS cluster and communicate with the ECS service
  # - Pull container images from ECR (Elastic Container Registry)
  # - Send logs to CloudWatch Logs
  # - Access other AWS services required by containerized applications
  create_iam_instance_profile = true
  iam_role_name               = "ecs"
  iam_role_path               = "/ecs/"
  iam_role_description        = "ECS instance role allowing EC2 instances to register with ECS cluster, pull ECR images, and write CloudWatch logs"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  }
}