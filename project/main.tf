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
  public_key = file("${path.module}/${var.pub_key_name}")
}

module "bastion_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.2.0"

  ami           = var.bastion_ami
  name          = var.bastion_name
  instance_type = var.bastion_type
  monitoring    = var.enable_bastion_monitoring
  subnet_id     = module.vpc.public_subnets[0]
  key_name      = aws_key_pair.bastion_key.key_name

  user_data_base64 = base64encode(
    templatefile(
      "${path.module}/init_bastion.sh",
      {
        private_key      = file("${path.module}/${var.prv_key_name}")
        init_sql_content = file("${path.module}/init.sql")
        rds_endpoint     = module.db_rds.db_instance_address
        rds_port         = var.rds_db_port
        rds_username     = var.rds_db_username
        rds_db_name      = var.rds_db_name
        rds_secret_arn   = module.db_rds.db_instance_master_user_secret_arn
        aws_region       = var.aws_region
      }
    )
  )

  # IAM role attachment
  iam_instance_profile = module.iam_bastion.instance_profile_name

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

  depends_on = [aws_key_pair.bastion_key]
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
  lifecycle {
    create_before_destroy = true
  }
}

module "iam_bastion" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name                    = "${var.vpc_name}-bastion_role"
  use_name_prefix         = false
  create_instance_profile = true
  description             = "This role is for Bastion instance"

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = ["sts:AssumeRole"]
      principals = [
        {
          type        = "Service"
          identifiers = ["ec2.amazonaws.com"]
        }
      ]
    }
  }

  policies = {
    AWSSecretsManagerClientReadOnlyAccess = "arn:aws:iam::aws:policy/AWSSecretsManagerClientReadOnlyAccess"
  }
}

module "iam_ecs_task_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name                    = "${var.vpc_name}-ecs-task-role"
  use_name_prefix         = false
  create_instance_profile = false

  description = "This role is for ECS tasks, using this custom role in order to avoid creating a new role for each task definition by the ecs module"

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = ["sts:AssumeRole"]
      principals = [
        {
          type        = "Service"
          identifiers = ["ecs-tasks.amazonaws.com"]
        }
      ]
    }
  }

  policies = {
    AWSSecretsManagerClientReadOnlyAccess = "arn:aws:iam::aws:policy/AWSSecretsManagerClientReadOnlyAccess"
  }
}

module "iam_ecs_task_exec_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name                    = "${var.vpc_name}-ecs-task-execution-role"
  use_name_prefix         = false
  create_instance_profile = false

  description = "This role is for ECS agents, using this custom role in order to avoid creating a new role for each task definition by the ecs module"

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = ["sts:AssumeRole"]
      principals = [
        {
          type        = "Service"
          identifiers = ["ecs-tasks.amazonaws.com"]
        }
      ]
    }
  }

  policies = {
    AmazonECSTaskExecutionRolePolicy = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  }
}

# ECS Cluster and Service
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = var.cluster_name

  cluster_capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 1
      base   = 1
    }
  }

  create_cloudwatch_log_group = false

  services = {
    frontend-task-definition = {
      cpu    = var.frontend_task_definition_cpu
      memory = var.frontend_task_definition_memory

      # ECS task execution role
      task_exec_iam_role_arn    = module.iam_ecs_task_exec_role.arn
      create_task_exec_iam_role = false

      # ECS task role
      tasks_iam_role_arn    = module.iam_ecs_task_role.arn
      create_tasks_iam_role = false

      requires_compatibilities = ["FARGATE"]
      network_mode             = "awsvpc"

      # remove asg configs
      enable_autoscaling       = false
      autoscaling_min_capacity = null
      autoscaling_max_capacity = null

      container_definitions = {
        frontend = {
          essential = true
          image     = "maissendev/todo-frontend"

          environment = [
            {
              name  = "API_URL"
              value = var.frontend_task_api_url == "" ? module.back_alb.dns_name : var.frontend_task_api_url
            }
          ]

          portMappings = [
            {
              containerPort = var.ecs_frontend_tasks_port
              protocol      = "tcp"
            }
          ]

          enable_cloudwatch_logging   = false
          create_cloudwatch_log_group = false
        }
      }

      desired_count = var.frontend_service_desired_tasks
      subnet_ids    = module.vpc.private_subnets

      capacity_provider_strategy = {
        FARGATE = {
          capacity_provider = "FARGATE"
          weight            = 1
          base              = 1
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.front_alb.target_groups["ecs-frontend-tasks-tg"].arn
          container_name   = "frontend"
          container_port   = var.ecs_frontend_tasks_port
        }
      }

      security_group_ingress_rules = {
        ingress_http = {
          from_port                    = var.ecs_frontend_tasks_port
          to_port                      = var.ecs_frontend_tasks_port
          ip_protocol                  = "tcp"
          referenced_security_group_id = module.front_alb.security_group_id
          description                  = "ALB HTTP access"
        }
      }

      security_group_egress_rules = {
        egress_all = {
          ip_protocol = "-1"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }

      vpc_id = module.vpc.vpc_id
    }

    backend-task-definition = {
      cpu    = var.backend_task_definition_cpu
      memory = var.backend_task_definition_memory

      # ECS task execution role
      task_exec_iam_role_arn    = module.iam_ecs_task_exec_role.arn
      create_task_exec_iam_role = false

      # ECS task role
      tasks_iam_role_arn    = module.iam_ecs_task_role.arn
      create_tasks_iam_role = false

      requires_compatibilities = ["FARGATE"]
      network_mode             = "awsvpc"

      # remove asg configs
      enable_autoscaling       = false
      autoscaling_min_capacity = null
      autoscaling_max_capacity = null

      container_definitions = {
        backend = {
          essential = true
          image     = "maissendev/todo-backend"

          environment = [
            {
              name  = "DB_PORT"
              value = tostring(module.db_rds.db_instance_port)
            },
            {
              name  = "DB_NAME"
              value = module.db_rds.db_instance_name
            },
            {
              name  = "DB_HOST"
              value = module.db_rds.db_instance_address
            }
          ]

          secrets = [
            {
              name      = "DB_USER"
              valueFrom = "${module.db_rds.db_instance_master_user_secret_arn}:username::"
            },
            {
              name      = "DB_PASSWORD"
              valueFrom = "${module.db_rds.db_instance_master_user_secret_arn}:password::"
            }
          ]

          portMappings = [
            {
              containerPort = var.ecs_backend_tasks_port
              protocol      = "tcp"
            }
          ]

          enable_cloudwatch_logging   = false
          create_cloudwatch_log_group = false
        }
      }

      desired_count = var.backend_service_desired_tasks
      subnet_ids    = module.vpc.private_subnets

      capacity_provider_strategy = {
        FARGATE = {
          capacity_provider = "FARGATE"
          weight            = 1
          base              = 1
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.back_alb.target_groups["ecs-backend-tasks-tg"].arn
          container_name   = "backend"
          container_port   = var.ecs_backend_tasks_port
        }
      }

      security_group_ingress_rules = {
        ingress_http = {
          from_port                    = var.ecs_backend_tasks_port
          to_port                      = var.ecs_backend_tasks_port
          ip_protocol                  = "tcp"
          referenced_security_group_id = module.back_alb.security_group_id
          description                  = "ALB HTTP access"
        }
      }

      security_group_egress_rules = {
        egress_rds_db = {
          ip_protocol = "tcp"
          from_port   = var.rds_db_port
          to_port     = var.rds_db_port
          cidr_ipv4   = "0.0.0.0/0"
          description = "Allow egress traffic to RDS db"
        }
      }

      vpc_id = module.vpc.vpc_id
    }
  }

  depends_on = [module.vpc, module.front_alb, module.back_alb]
}

# DATABASE RDS
module "db_rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "7.1.0"

  # RDS config
  identifier           = var.rds_instance_name
  engine               = var.rds_engine
  engine_version       = var.rds_engine_version
  major_engine_version = floor(var.rds_engine_version)
  instance_class       = var.rds_instance_class

  create_db_option_group = false

  # db config
  db_name                     = var.rds_db_name
  username                    = var.rds_db_username
  port                        = var.rds_db_port
  manage_master_user_password = true # rds module will create automatically the db password managed with secrets manager

  vpc_security_group_ids    = [module.db_rds_sg.security_group_id]
  deletion_protection       = false
  create_db_parameter_group = false

  allocated_storage     = var.rds_db_allocated_storage
  max_allocated_storage = var.rds_db_max_allocated_storage
  storage_type          = "gp2"

  # DB subnet group
  multi_az               = var.rds_multi_az
  create_db_subnet_group = true
  db_subnet_group_name   = module.vpc.database_subnet_group
  subnet_ids             = module.vpc.private_subnets

  depends_on = [module.vpc]
}

module "db_rds_sg" { # creating security groups for RDS
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name        = "RDS-SG"
  description = "Security group for RDS. Accepts traffic coming only within the vpc"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = var.rds_db_port
      to_port     = var.rds_db_port
      protocol    = "tcp"
      description = "Allow bastion access"
      cidr_blocks = var.vpc_cidr
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  ]
}
