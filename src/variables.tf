#########
# Github OIDC
#########
variable "github_repo" {
  description = "The Github repo that will assume the IAM role"
}

#########
# VPC
#########

variable "aws_region" {
  type        = string
  description = "The region for the provisioned aws infra"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC cidr block"
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  type        = string
  description = "the name of your vpc"
  default     = "my-vpc"
}

variable "vpc_azs" {
  type        = list(string)
  description = "the availability zones of subnets within the vpc"
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "enable or desable dns hostnames withing a vpc"
  default     = true
}

variable "enable_dns_support" {
  type        = bool
  description = "enable or desable dns support withing a vpc"
  default     = true
}

variable "private_subnets_cidrs" {
  type        = list(string)
  description = "the list of cidr blocks for the private subnets"
  default     = []
}

variable "public_subnets_cidrs" {
  type        = list(string)
  description = "the list of cidr blocks for the public subnets"
  default     = []
}

#########
# ALB
#########
variable "ecs_frontend_tasks_port" {
  type        = number
  description = "The port of ecs frontend tasks"
}

variable "ecs_backend_tasks_port" {
  type        = number
  description = "The port of ecs backend tasks"
}

#########
# ECS Auto Scaling
#########

variable "frontend_scaling_min_capacity" {
  type        = number
  description = "Minimum number of frontend ECS tasks"
  default     = 1
}

variable "frontend_scaling_max_capacity" {
  type        = number
  description = "Maximum number of frontend ECS tasks"
  default     = 4
}

variable "frontend_scaling_cpu_threshold" {
  type        = number
  description = "Target CPU utilization (%) to trigger frontend scaling"
  default     = 60
}

variable "frontend_scaling_memory_threshold" {
  type        = number
  description = "Target memory utilization (%) to trigger frontend scaling"
  default     = 70
}

variable "backend_scaling_min_capacity" {
  type        = number
  description = "Minimum number of backend ECS tasks"
  default     = 1
}

variable "backend_scaling_max_capacity" {
  type        = number
  description = "Maximum number of backend ECS tasks"
  default     = 4
}

variable "backend_scaling_cpu_threshold" {
  type        = number
  description = "Target CPU utilization (%) to trigger backend scaling"
  default     = 60
}

variable "backend_scaling_memory_threshold" {
  type        = number
  description = "Target memory utilization (%) to trigger backend scaling"
  default     = 70
}

#########
# ECS
#########

variable "cluster_name" {
  type        = string
  description = "ecs cluster name"
}

variable "frontend_task_definition_cpu" {
  type        = number
  description = "the vcpu to reserve for the frontend task definition"
}

variable "frontend_task_definition_memory" {
  type        = number
  description = "the memory to reserve for the frontend task definition"
}

variable "frontend_service_desired_tasks" {
  type        = number
  description = "the desired tasks number for frontend tasks"
}

variable "frontend_task_api_url" {
  description = "Backend API URL for the frontend application"
  type        = string
  default     = "" # it's set automatically
}

variable "backend_task_definition_cpu" {
  type        = number
  description = "the vcpu to reserve for the backend task definition"
}

variable "backend_task_definition_memory" {
  type        = number
  description = "the memory to reserve for the backend task definition"
}

variable "backend_service_desired_tasks" {
  type        = number
  description = "the desired tasks number for backend tasks"
}

#########
# CloudWatch Dashboard
#########

variable "cloudwatch_dashboard_name" {
  type        = string
  description = "Name of the CloudWatch dashboard"
  default     = "ecs-dashboard"
}

variable "cloudwatch_dashboard_period" {
  type        = number
  description = "Default metric period in seconds for dashboard widgets"
  default     = 300 # 5 minutes
}

variable "cloudwatch_logs_limit" {
  type        = number
  description = "Number of log lines to display in each log widget"
  default     = 50
}

#########
# RDS
#########

variable "rds_instance_name" {
  type        = string
  description = "The name of the RDS instance"
  default     = "app_db"
}

variable "rds_engine" {
  type        = string
  description = "The database engine to use"
  default     = "postgres"
}

variable "rds_engine_version" {
  type        = string
  description = "The engine version to use"
  default     = "17"
}

variable "rds_instance_class" {
  type        = string
  description = "The instance type of the RDS instance"
  default     = "db.t4g.small"
}

variable "rds_db_name" {
  type        = string
  description = "The DB name to create. If omitted, no database is created initially"
}

variable "rds_db_username" {
  type        = string
  description = "Username for the master DB user"
  default     = "master"
}

variable "rds_db_port" {
  type        = string
  description = "The port on which the DB accepts connections"
  default     = "5432"
}

variable "rds_db_allocated_storage" {
  type        = number
  description = "The allocated storage in gigabytes, must be >= 20"
  default     = 20
}

variable "rds_db_max_allocated_storage" {
  type        = number
  description = "Specifies the value for Storage Autoscaling"
  default     = 100
}

variable "rds_multi_az" {
  type        = bool
  description = "Specifies if the RDS instance is multi-AZ"
  default     = false
}