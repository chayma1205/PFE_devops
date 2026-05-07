#########
# ECR
#########
output "backend_repo_url" {
  description = "Backend ECR repository URL (used to push/pull images)"
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_repo_url" {
  description = "Frontend ECR repository URL (used to push/pull images)"
  value       = aws_ecr_repository.frontend.repository_url
}

#########
# Github OIDC
#########
output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.github_oidc.oidc_provider_arn
}

# output "github_role_arn" {
#   description = "ARN of the GitHub Actions IAM role"
#   value       = module.github_oidc.oidc_role_arn
# }

#########
# VPC
#########

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnets
}

#########
# ALB
#########
output "front_alb_dns" {
  description = "The dns name of the frontend alb"
  value       = module.front_alb.dns_name
}

output "back_alb_dns" {
  description = "The dns name of the backend alb"
  value       = module.back_alb.dns_name
}

#########
# ECS Auto Scaling
#########

output "frontend_autoscaling_target_id" {
  description = "Frontend autoscaling target resource ID"
  value       = aws_appautoscaling_target.frontend.resource_id
}

output "frontend_autoscaling_min_capacity" {
  description = "Frontend minimum task count"
  value       = aws_appautoscaling_target.frontend.min_capacity
}

output "frontend_autoscaling_max_capacity" {
  description = "Frontend maximum task count"
  value       = aws_appautoscaling_target.frontend.max_capacity
}

output "backend_autoscaling_target_id" {
  description = "Backend autoscaling target resource ID"
  value       = aws_appautoscaling_target.backend.resource_id
}

output "backend_autoscaling_min_capacity" {
  description = "Backend minimum task count"
  value       = aws_appautoscaling_target.backend.min_capacity
}

output "backend_autoscaling_max_capacity" {
  description = "Backend maximum task count"
  value       = aws_appautoscaling_target.backend.max_capacity
}

#########
# ECS
#########

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs.cluster_arn
}

#########
# CloudWatch
#########

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.ecs.dashboard_name
}

output "cloudwatch_dashboard_url" {
  description = "Direct link to the CloudWatch dashboard in the AWS console"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.ecs.dashboard_name}"
}


#########
# RDS
#########

output "rds_address" {
  description = "RDS instance address"
  value       = module.db_rds.db_instance_address
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.db_rds.db_instance_port
}

output "rds_database_name" {
  description = "Name of the database"
  value       = module.db_rds.db_instance_name
}

output "rds_secret_arn" {
  description = "RDS secret ARN (from secrets manager)"
  value       = module.db_rds.db_instance_master_user_secret_arn
}

# RDS Resource Identifiers
output "rds_instance_id" {
  description = "RDS instance ID"
  value       = module.db_rds.db_instance_identifier
}