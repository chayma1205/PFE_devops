output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}
output "front_alb_dns" {
  description = "The dns name of the frontend alb"
  value       = module.front_alb.dns_name
}

output "back_alb_dns" {
  description = "The dns name of the backend alb"
  value       = module.back_alb.dns_name
}
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs.cluster_arn
}

output "ecr_backend_repository_url" {
  value       = aws_ecr_repository.backend.repository_url
  description = "ECR repo URL for backend (push images here)"
}

output "ecr_frontend_repository_url" {
  value       = aws_ecr_repository.frontend.repository_url
  description = "ECR repo URL for frontend"

}

output "rds_endpoint" {
  description = "The connection endpoint"
  value       = module.db_rds.db_instance_endpoint
}
output "rds_address" {
  value = module.db_rds.db_instance_address
}
