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

  map_public_ip_on_launch = true

  public_subnet_names = [
    for i, k in var.public_subnets_cidrs : "pub-subnet-${i + 1}"
  ]

  private_subnet_names = [
    for i, k in var.private_subnets_cidrs : "prv-subnet-${i + 1}"
  ]

  # create only a single nat gateway
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  nat_gateway_tags = {
    Name = "${var.vpc_name}-nat-gw"
  }

  igw_tags = {
    Name = "${var.vpc_name}-igw"
  }

  public_route_table_tags = {
    Name = "${var.vpc_name}-public-rt"
  }

  private_route_table_tags = {
    Name = "${var.vpc_name}-private-rt"
  }
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion_key_pair"
  public_key = file("${path.module}/${var.bastion_key_name}")
}

module "bastion_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.2.0"

  ami           = var.bastion_ami
  name          = var.bastion_name
  instance_type = var.bastion_type
  monitoring    = var.enable_bastion_monitoring
  subnet_id     = module.vpc.public_subnets[0]

  key_name  = aws_key_pair.bastion_key.key_name
  user_data = var.bastion_user_data != null ? file("${path.module}/${var.bastion_user_data}") : ""

  # security group config
  create_security_group = true
  security_group_name   = "${var.vpc_name}-bastion_sg"

  security_group_ingress_rules = {
    allow_ssh = {
      cidr_ipv4   = var.bastion_ingress_rule_cidr
      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22
    }

    # the bastion instance will temporarly host the database for the ecs tasks
    allow_database_port = {
      cidr_ipv4   = var.vpc_cidr
      ip_protocol = "tcp"
      from_port   = 5500
      to_port     = 5500
    }
  }

  security_group_egress_rules = {
    allow_all = {
      cidr_ipv4   = "0.0.0.0/0"
      ip_protocol = "-1"
    }
  }

  # instance storage
  root_block_device = {
    volume_size = var.bastion_storage_size
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.vpc_name}-bastion"
    Description = "Allow ssh to vpc's private instances"
  }
}

# IAM role for ECS task execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name        = "${var.vpc_name}-ecs-task-execution-role"
  path        = "/ecs/"
  description = "ECS task execution role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ALB
module "front_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.5.0"

  name               = "front-alb"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  load_balancer_type = "application"
  internal           = false

  # Security Group
  security_group_name            = "frontend-alb-sg"
  security_group_use_name_prefix = false
  security_group_ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all_traffic = {
      ip_protocol = "-1"
      cidr_ipv4   = var.vpc_cidr
      description = "allow outbound traffic only inside the vpc"
    }
  }

  listeners = {
    https = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ecs-frontend-tasks-tg"
      }
    }
  }

  target_groups = {
    ecs-frontend-tasks-tg = {
      name              = "frontend-tg"
      protocol          = "HTTP"
      port              = var.ecs_frontend_tasks_port
      target_type       = "ip"
      create_attachment = false # avoid attatching ips when creating the alb
    }
  }

  depends_on = [module.vpc]
}

module "back_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.5.0"

  name               = "back-alb"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  load_balancer_type = "application"
  internal           = false

  # Security Group
  security_group_name            = "backend-alb-sg"
  security_group_use_name_prefix = false
  security_group_ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all_traffic = {
      ip_protocol = "-1"
      cidr_ipv4   = var.vpc_cidr
      description = "allow outbound traffic only inside the vpc"
    }
  }

  listeners = {
    https = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ecs-backend-tasks-tg"
      }
    }
  }

  target_groups = {
    ecs-backend-tasks-tg = {
      name              = "backend-tg"
      protocol          = "HTTP"
      port              = var.ecs_backend_tasks_port
      target_type       = "ip"
      create_attachment = false # avoid attatching ips when creating the alb
    }
  }

  depends_on = [module.vpc, module.front_alb]
}

resource "aws_security_group" "ecs_instance_sg" {
  description = "Security group for ECS EC2 instances"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow any outbound traffic"
  }

  ingress {
    from_port       = var.ecs_frontend_tasks_port
    to_port         = var.ecs_frontend_tasks_port
    protocol        = "tcp"
    security_groups = [module.front_alb.security_group_id]
    description     = "allow inbound traffic to frontend ecs tasks"
  }

  ingress {
    from_port       = var.ecs_backend_tasks_port
    to_port         = var.ecs_backend_tasks_port
    protocol        = "tcp"
    security_groups = [module.back_alb.security_group_id]
    description     = "allow inbound traffic to backend ecs tasks"
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [module.bastion_instance.security_group_id]
    description     = "SSH from Bastion"
  }

  tags = {
    Name = "${var.vpc_name}-ecs-instance-sg"
  }
}

# Auto Scaling Group
module "web_asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  name             = var.asg_name
  use_name_prefix  = false
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  vpc_zone_identifier = module.vpc.private_subnets

  # launch template config
  launch_template_name        = var.asg_launch_template_name
  launch_template_description = var.asg_launch_template_description
  image_id                    = var.asg_image_id
  instance_type               = var.asg_instance_type
  enable_monitoring           = false
  security_groups             = [aws_security_group.ecs_instance_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config
    EOF
  )

  create_iam_instance_profile = true
  iam_role_name               = "${var.vpc_name}-ecsExecutionRole"
  iam_role_description        = "this role is needed for ecs"
  iam_role_policies = {
    ecs = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  }

  tags = {
    Name    = "${var.vpc_name}-${var.asg_name}"
    Purpose = "Deploy and scale simple web app - front and back"
  }

  depends_on = [module.vpc]
}

# ECS Cluster and Service
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = var.cluster_name

  capacity_providers = {
    web_asg_cp = {
      auto_scaling_group_provider = {
        auto_scaling_group_arn         = module.web_asg.autoscaling_group_arn
        managed_termination_protection = "DISABLED"

        managed_scaling = {
          maximum_scaling_step_size = 2
          minimum_scaling_step_size = 1
          status                    = "ENABLED"
          target_capacity           = 100
        }
      }
    }
  }

  create_cloudwatch_log_group = false
  cluster_capacity_providers  = ["web_asg_cp"]

  default_capacity_provider_strategy = {
    web_asg_cp = {
      weight = 1
      base   = 0
    }
  }

  services = {
    # frontend task definition
    frontend-task-definition = {

      # Task definition attributes
      cpu    = var.frontend_task_definition_cpu
      memory = var.frontend_task_definition_memory

      task_exec_iam_role_arn      = aws_iam_role.ecs_task_execution_role.arn
      create_task_exec_iam_role   = false
      create_cloudwatch_log_group = false

      requires_compatibilities = ["EC2"]
      network_mode             = "awsvpc"

      container_definitions = {
        frontend = {
          essential = true
          image     = "maissendev/todo-frontend"

          port_mappings = {
            http = {
              name          = "http"
              containerPort = var.ecs_frontend_tasks_port
              hostPort      = 0 # dynamic port
              protocol      = "tcp"
            }
          }

          enable_cloudwatch_logging   = false
          create_cloudwatch_log_group = false
        }
      }

      # Service attributes
      desired_count = var.frontend_service_desired_tasks
      subnet_ids    = module.vpc.private_subnets

      # Use the capacity provider instead of launch_type
      capacity_provider_strategy = {
        web_asg_cp = {
          capacity_provider = "web_asg_cp"
          weight            = 1
          base              = 1
        }
      }

      # alb config
      load_balancer = {
        service = {
          target_group_arn = module.front_alb.target_groups["ecs-frontend-tasks-tg"].arn
          container_name   = "frontend"
          container_port   = var.ecs_frontend_tasks_port
        }
      }

      security_group_rules = {
        ingress_http = {
          type        = "ingress"
          from_port   = var.ecs_frontend_tasks_port
          to_port     = var.ecs_frontend_tasks_port
          protocol    = "tcp"
          cidr_blocks = [var.vpc_cidr]
          description = "VPC-only HTTP access"
        }

        egress_http = {
          type        = "egress"
          from_port   = var.ecs_backend_tasks_port
          to_port     = var.ecs_backend_tasks_port
          protocol    = "tcp"
          cidr_blocks = [var.vpc_cidr]
          description = "VPC-only HTTP egress"
        }
      }
    }
  }

  depends_on = [module.web_asg, module.vpc, module.front_alb]
}
