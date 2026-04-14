variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
}

variable "github_repo" {
  description = "The Github repo that will assume the IAM role"
}

variable "ecr_repo_name" {
  description = "Base ECR repository name"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Base ECS cluster name (without env)"
  type        = string
}

variable "ecs_service_name" {
  description = "Base ECS service name (without env)"
  type        = string
}

variable "ecs_task_def_name" {
  description = "Base ECS task definition name (without env)"
  type        = string
}
