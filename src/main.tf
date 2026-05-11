# ECR for backend image
resource "aws_ecr_repository" "backend" {
  name                 = "backend-todo"
  image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

  image_tag_mutability_exclusion_filter {
    filter      = "latest"
    filter_type = "WILDCARD"
  }
}

# ECR for frontend image
resource "aws_ecr_repository" "frontend" {
  name                 = "frontend-todo"
  image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

  image_tag_mutability_exclusion_filter {
    filter      = "latest"
    filter_type = "WILDCARD"
  }
}

# Github OIDC for github actions 
module "github_oidc" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "2.2.2"

  role_name = "github-actions-role"

  repositories = [
    var.github_repo
  ]

  oidc_role_attach_policies = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  ]
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

# Frontend Task Definition
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
      image     = "maissendev/todo-frontend"
      essential = true

      readonlyRootFilesystem = false

      environment = [
        {
          name  = "API_URL"
          value = var.frontend_task_api_url == "" ? "http://${module.back_alb.dns_name}" : var.frontend_task_api_url
        }
      ]

      portMappings = [
        {
          containerPort = var.ecs_frontend_tasks_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/frontend-task-definition"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
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

# Frontend CloudWatch Log Group
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/frontend-group"
  retention_in_days = 0

  tags = {
    Name = "frontend-group"
  }
}

# Backend Task Definition
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
      image     = "maissendev/todo-backend"
      essential = true

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

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/backend-task-definition"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
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

# Backend CloudWatch Log Group
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/backend-group"
  retention_in_days = 0

  tags = {
    Name = "backend-group"
  }
}

# ECS Auto Scaling
resource "aws_appautoscaling_target" "frontend" {
  service_namespace  = "ecs"
  resource_id        = "service/${module.ecs.cluster_name}/frontend-service"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.frontend_scaling_min_capacity
  max_capacity       = var.frontend_scaling_max_capacity
  tags               = {}

  lifecycle {
    ignore_changes = [tags, tags_all]
  }

  depends_on = [module.ecs]
}

resource "aws_appautoscaling_policy" "frontend_cpu" {
  name               = "frontend-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.frontend.service_namespace
  resource_id        = aws_appautoscaling_target.frontend.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value       = var.frontend_scaling_cpu_threshold

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "frontend_memory" {
  name               = "frontend-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.frontend.service_namespace
  resource_id        = aws_appautoscaling_target.frontend.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value       = var.frontend_scaling_memory_threshold

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

resource "aws_appautoscaling_target" "backend" {
  service_namespace  = "ecs"
  resource_id        = "service/${module.ecs.cluster_name}/backend-service"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.backend_scaling_min_capacity
  max_capacity       = var.backend_scaling_max_capacity
  tags               = {}

  lifecycle {
    ignore_changes = [tags, tags_all]
  }

  depends_on = [module.ecs]
}

resource "aws_appautoscaling_policy" "backend_cpu" {
  name               = "backend-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.backend.service_namespace
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value       = var.backend_scaling_cpu_threshold

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "backend_memory" {
  name               = "backend-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.backend.service_namespace
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value       = var.backend_scaling_memory_threshold

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

# SNS Topic for ECS alerts
resource "aws_sns_topic" "ecs_alerts" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "email_alerts" {
  for_each = toset(var.sns_alert_emails)

  topic_arn = aws_sns_topic.ecs_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# CloudWatch frontend alerts
resource "aws_cloudwatch_metric_alarm" "frontend_cpu_high" {
  alarm_name          = "frontend-cpu-high"
  alarm_description   = "Frontend ECS CPU utilization exceeded ${var.frontend_scaling_cpu_threshold}%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.frontend_scaling_cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = "frontend-service"
  }

  alarm_actions = [aws_sns_topic.ecs_alerts.arn]
  ok_actions    = [aws_sns_topic.ecs_alerts.arn]

  depends_on = [module.ecs]
}

resource "aws_cloudwatch_metric_alarm" "frontend_memory_high" {
  alarm_name          = "frontend-memory-high"
  alarm_description   = "Frontend ECS memory utilization exceeded ${var.frontend_scaling_memory_threshold}%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.frontend_scaling_memory_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = "frontend-service"
  }

  alarm_actions = [aws_sns_topic.ecs_alerts.arn]
  ok_actions    = [aws_sns_topic.ecs_alerts.arn]

  depends_on = [module.ecs]
}

# CloudWatch backend alerts
resource "aws_cloudwatch_metric_alarm" "backend_cpu_high" {
  alarm_name          = "backend-cpu-high"
  alarm_description   = "Backend ECS CPU utilization exceeded ${var.backend_scaling_cpu_threshold}%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.backend_scaling_cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = "backend-service"
  }

  alarm_actions = [aws_sns_topic.ecs_alerts.arn]
  ok_actions    = [aws_sns_topic.ecs_alerts.arn]

  depends_on = [module.ecs]
}

resource "aws_cloudwatch_metric_alarm" "backend_memory_high" {
  alarm_name          = "backend-memory-high"
  alarm_description   = "Backend ECS memory utilization exceeded ${var.backend_scaling_memory_threshold}%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.backend_scaling_memory_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = "backend-service"
  }

  alarm_actions = [aws_sns_topic.ecs_alerts.arn]
  ok_actions    = [aws_sns_topic.ecs_alerts.arn]

  depends_on = [module.ecs]
}

# ECS Cluster and Service
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = var.cluster_name

  cluster_capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = 0

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
      container_definitions = {} # using a custom one

      # ECS task role
      create_tasks_iam_role = false

      # remove asg configs
      enable_autoscaling       = false
      autoscaling_min_capacity = null
      autoscaling_max_capacity = null

      desired_count = var.frontend_service_desired_tasks
      subnet_ids    = module.vpc.private_subnets

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

    backend = {

      name   = "backend-service"
      family = "backend-task-definition"

      create_task_definition = false
      ignore_task_definition_changes = true
      task_definition_arn    = aws_ecs_task_definition.backend.arn
      container_definitions = {} # using a custom one

      desired_count    = var.backend_service_desired_tasks
      subnet_ids       = module.vpc.private_subnets
      assign_public_ip = false

      # ECS task execution role
      task_exec_iam_role_arn    = module.iam_ecs_task_exec_role.arn
      create_task_exec_iam_role = false

      # remove asg configs
      enable_autoscaling       = false
      autoscaling_min_capacity = null
      autoscaling_max_capacity = null

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
        egress_all = {
          ip_protocol = "-1"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }

      vpc_id = module.vpc.vpc_id
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

resource "aws_cloudwatch_dashboard" "ecs" {
  dashboard_name = var.cloudwatch_dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      # ECS CPU Utilization
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS CPU Utilization"
          view   = "timeSeries"
          stacked = false
          region = var.aws_region
          period = var.cloudwatch_dashboard_period
          stat   = "Average"
          metrics = [
            ["AWS/ECS", "CPUUtilization",
              "ClusterName", module.ecs.cluster_name,
              "ServiceName", "frontend-service",
              { label = "Frontend CPU" }
            ],
            ["AWS/ECS", "CPUUtilization",
              "ClusterName", module.ecs.cluster_name,
              "ServiceName", "backend-service",
              { label = "Backend CPU" }
            ]
          ]
          yAxis = { left = { min = 0, max = 100 } }
        }
      },

      # ECS Memory Utilization
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS Memory Utilization"
          view   = "timeSeries"
          stacked = false
          region = var.aws_region
          period = var.cloudwatch_dashboard_period
          stat   = "Average"
          metrics = [
            ["AWS/ECS", "MemoryUtilization",
              "ClusterName", module.ecs.cluster_name,
              "ServiceName", "frontend-service",
              { label = "Frontend Memory" }
            ],
            ["AWS/ECS", "MemoryUtilization",
              "ClusterName", module.ecs.cluster_name,
              "ServiceName", "backend-service",
              { label = "Backend Memory" }
            ]
          ]
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
    ]
  })

  depends_on = [
    module.ecs,
    aws_cloudwatch_log_group.frontend,
    aws_cloudwatch_log_group.backend
  ]
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
