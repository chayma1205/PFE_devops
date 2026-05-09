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

  map_public_ip_on_launch = true #! ?

  public_subnet_names = [
    for i, k in var.public_subnets_cidrs : "pub-subnet-${i + 1}"
  ]

  private_subnet_names = [
    for i, k in var.private_subnets_cidrs : "-subnet-${i + 1}"
  ]

  enable_nat_gateway = true
  single_nat_gateway = true
  reuse_nat_ips       = false
  external_nat_ip_ids = []

  public_subnet_suffix  = "pub"
  private_subnet_suffix = "prv"
  
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
      cidr_ipv4   = "0.0.0.0/0"
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
      cidr_ipv4   = "0.0.0.0/0"
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

//ecr
resource "aws_ecr_repository" "backend" {
  name                 = "backend-todo"
  image_tag_mutability = "MUTABLE"   
  force_delete         = true
}

resource "aws_ecr_repository" "frontend" {
  name                 = "frontend-todo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

//ecs
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = var.cluster_name

  cluster_capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  create_cloudwatch_log_group            = false
  cloudwatch_log_group_retention_in_days = 7

  services = {
    frontend = {

      name   = "frontend-service"
      family = "frontend-task-definition"
      
      create_task_definition = false
      task_definition_arn    = aws_ecs_task_definition.frontend.arn
      ignore_task_definition_changes = true

      # ECS task execution role
      task_exec_iam_role_arn    = module.iam_ecs_task_exec_role.arn
      create_task_exec_iam_role = false

      desired_count = var.frontend_service_desired_tasks
      
      subnet_ids    = module.vpc.private_subnets
      vpc_id = module.vpc.vpc_id


      # remove asg configs
      enable_autoscaling       = true
      autoscaling_min_capacity = 2
      autoscaling_max_capacity = 5

      # Target Tracking Policies (CPU + Memory)
      autoscaling_policies = {
        cpu = {
          policy_type = "TargetTrackingScaling"

          target_tracking_scaling_policy_configuration = {
            predefined_metric_specification = {
              predefined_metric_type = "ECSServiceAverageCPUUtilization"
            }

            target_value       = 70
            scale_in_cooldown  = 120
            scale_out_cooldown = 30
          }
        }

        memory = {
          policy_type = "TargetTrackingScaling"

          target_tracking_scaling_policy_configuration = {
            predefined_metric_specification = {
              predefined_metric_type = "ECSServiceAverageMemoryUtilization"
            }

            target_value       = 60
            scale_in_cooldown  = 120
            scale_out_cooldown = 30
          }
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

    container_definitions = {}
    }

    backend = {

      name   = "backend-service"
      family = "backend-task-definition"

      create_task_definition = false
      ignore_task_definition_changes = true
      task_definition_arn    = aws_ecs_task_definition.backend.arn

      task_exec_iam_role_arn    = module.iam_ecs_task_exec_role.arn
      create_task_exec_iam_role = false

      desired_count    = var.backend_service_desired_tasks

      subnet_ids       = module.vpc.private_subnets
      assign_public_ip = false
      vpc_id = module.vpc.vpc_id


      # add as configs
      enable_autoscaling       = true
      autoscaling_min_capacity = 2
      autoscaling_max_capacity = 5

      autoscaling_policies = {
      cpu = {
        policy_type = "TargetTrackingScaling"

        target_tracking_scaling_policy_configuration = {
          predefined_metric_specification = {
            predefined_metric_type = "ECSServiceAverageCPUUtilization"
          }

          target_value       = 70
          scale_in_cooldown  = 300
          scale_out_cooldown = 60
        }
      }

      memory = {
        policy_type = "TargetTrackingScaling"

        target_tracking_scaling_policy_configuration = {
          predefined_metric_specification = {
            predefined_metric_type = "ECSServiceAverageMemoryUtilization"
          }

          target_value       = 70
          scale_in_cooldown  = 300
          scale_out_cooldown = 60
        }
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
        egress_all = {
          ip_protocol = "-1"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }
    container_definitions = {}

    }
  }

  depends_on = [
    module.vpc,
    module.front_alb,
    module.back_alb,
    aws_ecs_task_definition.frontend,
    aws_ecs_task_definition.backend,
    aws_cloudwatch_log_group.frontend,
    aws_cloudwatch_log_group.backend
  ]
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
    AWSSecretsManagerClientReadOnlyAccess = "arn:aws:iam::aws:policy/AWSSecretsManagerClientReadOnlyAccess" // the ecs agent needs to fetch secrets from secrets manager service
    AmazonECSTaskExecutionRolePolicy      = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  }
}

//ecs services
resource "aws_ecs_task_definition" "backend" {
  family                   = "backend-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_task_definition_cpu
  memory                   = var.backend_task_definition_memory
  execution_role_arn       = module.iam_ecs_task_exec_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${aws_ecr_repository.backend.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = var.ecs_backend_tasks_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DB_HOST",     value = module.db_rds.db_instance_address },
        { name = "DB_PORT",     value = tostring(module.db_rds.db_instance_port) },
        { name = "DB_NAME",     value = module.db_rds.db_instance_name },
        { name = "DB_USER",     value = var.rds_db_username },
        { name = "DB_ENGINE",   value = "postgres" },           # Maybe the app checks this
        //{ name = "DB_DIALECT",  value = "postgresql" }            # Some apps use this
        { name = "DATABASE_URL", value = "postgresql://${var.rds_db_username}:dummy@${module.db_rds.db_instance_address}:${module.db_rds.db_instance_port}/${module.db_rds.db_instance_name}" }      
      ]
      secrets = [
        //{name      = "DB_USER", valueFrom = "${module.db_rds.db_instance_master_user_secret_arn}:username::"},
        {
          name      = "DB_PASSWORD"
          valueFrom = "${module.db_rds.db_instance_master_user_secret_arn}:password::"
          }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])
  lifecycle {
    ignore_changes = [container_definitions] # Ignored because the CD pipeline will update each time the container image
  }

  tags = {
    Name = "backend-task-definition"
  }
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "frontend-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.frontend_task_definition_cpu
  memory                   = var.frontend_task_definition_memory
  execution_role_arn       = module.iam_ecs_task_exec_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${aws_ecr_repository.frontend.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = var.ecs_frontend_tasks_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "API_URL"
          value = var.frontend_task_api_url == "" ? "http://${module.back_alb.dns_name}" : var.frontend_task_api_url
        }
      ]

      logConfiguration = { //tells ECS how to handle logs for this container.
        logDriver = "awslogs" //use CloudWatch as the place to store logs
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
          "awslogs-create-group"  = "true" //automatically create it if it doesnt exist
        }
      }
    }
  ])
  lifecycle {
    ignore_changes = [container_definitions] # Ignored because the CD pipeline will update each time the container image
  }

  tags = {
    Name = "frontend-task-definition"
  }

}


resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/frontend-task-definition"
  //retention_in_days = 7
  
  tags = {
    Name        = "frontend-logs"
    Service     = "frontend"
    Environment = "qa"
  }
  lifecycle {
    ignore_changes = [retention_in_days]
  }
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/backend-task-definition"
  //retention_in_days = 7
  
  tags = {
    Name        = "backend-logs"
    Service     = "backend"
    Environment = "qa"
  }
  lifecycle {
    ignore_changes = [retention_in_days]
  }
}



module "db_rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "7.1.0"   

  identifier           = var.rds_instance_name
  engine               = var.rds_engine
  engine_version       = var.rds_engine_version
  instance_class       = var.rds_instance_class  

  create_db_option_group = false

  db_name  = var.rds_db_name
  username = var.rds_db_username 
  port     = var.rds_db_port
  manage_master_user_password = true

  vpc_security_group_ids   = [module.db_rds_sg.security_group_id]  
  deletion_protection    = false               
  create_db_parameter_group = false  

  allocated_storage    = var.rds_db_allocated_storage
  max_allocated_storage = var.rds_db_max_allocated_storage
  storage_type         = "gp2"              

  multi_az               = var.rds_multi_az 
  create_db_subnet_group = true
  db_subnet_group_name   = module.vpc.database_subnet_group
  subnet_ids           = module.vpc.private_subnets
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

# ==================== SNS TOPIC FOR ALERTS ====================
resource "aws_sns_topic" "ecs_alerts" {
  name = "ecs-high-utilization-alerts"
  
  tags = {
    Name        = "ecs-alerts"
    Environment = "qa"
  }
}

# Email Subscription (Change this email to yours!)
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.ecs_alerts.arn
  protocol  = "email"
  endpoint  = "lamisdhaouadi25@gmail.com"   # ←←← CHANGE THIS TO YOUR REAL EMAIL
}

# ==================== CLOUDWATCH ALARMS ====================

# Frontend - High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "frontend_high_cpu" {
  alarm_name          = "frontend-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300          # 5 minutes
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Frontend service CPU is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = "frontend-service"
  }

  alarm_actions = [aws_sns_topic.ecs_alerts.arn]
  ok_actions    = [aws_sns_topic.ecs_alerts.arn]
}

# Frontend - High Memory Alarm
resource "aws_cloudwatch_metric_alarm" "frontend_high_memory" {
  alarm_name          = "frontend-high-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Frontend service Memory is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = "frontend-service"
  }

  alarm_actions = [aws_sns_topic.ecs_alerts.arn]
  ok_actions    = [aws_sns_topic.ecs_alerts.arn]
}

# Backend - High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "backend_high_cpu" {
  alarm_name          = "backend-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Backend service CPU is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = "backend-service"
  }

  alarm_actions = [aws_sns_topic.ecs_alerts.arn]
  ok_actions    = [aws_sns_topic.ecs_alerts.arn]
}

# Backend - High Memory Alarm
resource "aws_cloudwatch_metric_alarm" "backend_high_memory" {
  alarm_name          = "backend-high-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Backend service Memory is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = "backend-service"
  }

  alarm_actions = [aws_sns_topic.ecs_alerts.arn]
  ok_actions    = [aws_sns_topic.ecs_alerts.arn]
}

