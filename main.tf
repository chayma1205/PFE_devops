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
  enable_nat_gateway = true
  single_nat_gateway = true


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

  name = "ecs-ec2-asg"

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  vpc_zone_identifier = module.vpc.public_subnets
  key_name = "ecs-debug-key"

  health_check_type   = "EC2"
  # Network interface to get public IP
  network_interfaces = [
    {
      device_index               = 0
      subnet_id                  = module.vpc.public_subnets[0]
      associate_public_ip_address = true
      # optional: security group
      security_groups = []
    }
  ]

  # Launch template
  launch_template_name   = "ecs-ec2-lt"
  update_default_version = true

  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.micro"
  user_data = base64encode(<<EOF
  #!/bin/bash
  echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config
  EOF
  )



  create_iam_instance_profile = true
  iam_role_name               = "ecsInstanceRole"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  }

  tags = {
    Environment = "dev"
  
  }
  
}
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "7.3.0"

  name = var.cluster_name
  create_cloudwatch_log_group = false


  cluster_capacity_providers = ["ec2"]

  default_capacity_provider_strategy = {
    ec2 = {
      weight = 100
      base   = 1
    }
  }

  capacity_providers = {
    ec2 = {
      auto_scaling_group_provider = {
        auto_scaling_group_arn = module.asg.autoscaling_group_arn

        managed_scaling = {
          status          = "ENABLED"
          target_capacity = 80
        }

        managed_termination_protection = "DISABLED"
      }
    }
  }

  tags = {
    Environment = "dev"
  }
}
