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
# ASG
#########

output "asg_name" {
  description = "Autoscaling group name"
  value       = module.web_asg.autoscaling_group_name
}

output "asg_arn" {
  description = "Autoscaling group ARN"
  value       = module.web_asg.autoscaling_group_arn
}

output "asg_id" {
  description = "Autoscaling group ID"
  value       = module.web_asg.autoscaling_group_id
}

output "launch_template_id" {
  description = "Launch template ID used by the autoscaling group"
  value       = module.web_asg.launch_template_id
}

output "launch_template_latest_version" {
  description = "Latest launch template version"
  value       = module.web_asg.launch_template_latest_version
}

#########
# ECS
#########

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs_1.cluster_name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs_1.cluster_arn
}
