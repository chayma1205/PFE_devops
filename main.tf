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

# create a single IAM role for all ECS instances
resource "aws_iam_role" "ecs_instance_role" {
  name        = "${var.vpc_name}-ecs-instance-role"
  path        = "/ecs/"
  description = "ECS instance role allowing EC2 instances to register with ECS cluster, pull ECR images, and write CloudWatch logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  depends_on = [module.vpc]
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.vpc_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

module "asg_1" {
  source = "terraform-aws-modules/autoscaling/aws"

  depends_on = [module.vpc]

  name               = var.asg_name
  use_name_prefix    = false
  min_size           = var.asg_min_size
  max_size           = var.asg_max_size
  desired_capacity   = var.asg_desired_capacity
  availability_zones = var.vpc_azs

  launch_template_name        = var.asg_launch_template_name
  launch_template_description = var.asg_launch_template_description
  image_id                    = var.asg_image_id
  instance_type               = var.asg_instance_type
  enable_monitoring           = true

  create_iam_instance_profile = false
  iam_instance_profile_arn    = aws_iam_instance_profile.ecs_instance_profile.arn

  tags = {
    Name = "${var.vpc_name}-${var.asg_name}"
  }
}


module "ecs_1" {
  source     = "terraform-aws-modules/ecs/aws"
  depends_on = [module.asg_1]

  cluster_name = var.cluster_name

  capacity_providers = {

    asg_cp_1 = {
      auto_scaling_group_provider = {
        auto_scaling_group_arn = module.asg_1.autoscaling_group_arn
        # managed_scaling = {
        #   status = "ENABLED"
        #   target_capacity           = 100
        #   minimum_scaling_step_size = 1
        #   maximum_scaling_step_size = 100
        # }
      }
    }

  }

  cluster_capacity_providers = ["asg_cp_1"]
}