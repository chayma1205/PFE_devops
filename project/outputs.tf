# #########
# # VPC
# #########

# output "vpc_id" {
#   description = "ID of the VPC"
#   value       = module.vpc.vpc_id
# }

# output "public_subnet_ids" {
#   description = "IDs of public subnets"
#   value       = module.vpc.public_subnets
# }

# output "private_subnet_ids" {
#   description = "IDs of private subnets"
#   value       = module.vpc.private_subnets
# }

# #########
# # BASTION INSTANCE
# #########
# output "bastion_public_ip" {
#   description = "The public ip of bastion instance"
#   value       = module.bastion_instance.public_ip
# }

# #########
# # ASG
# #########

# output "asg_name" {
#   description = "Autoscaling group name"
#   value       = module.web_asg.autoscaling_group_name
# }

# output "asg_arn" {
#   description = "Autoscaling group ARN"
#   value       = module.web_asg.autoscaling_group_arn
# }

# output "asg_id" {
#   description = "Autoscaling group ID"
#   value       = module.web_asg.autoscaling_group_id
# }

# output "launch_template_id" {
#   description = "Launch template ID used by the autoscaling group"
#   value       = module.web_asg.launch_template_id
# }

# output "launch_template_latest_version" {
#   description = "Latest launch template version"
#   value       = module.web_asg.launch_template_latest_version
# }

# #########
# # ALB
# #########
# output "front_alb_dns" {
#   description = "The dns name of the frontend alb"
#   value       = module.front_alb.dns_name
# }

# output "back_alb_dns" {
#   description = "The dns name of the backend alb"
#   value       = module.back_alb.dns_name
# }


# #########
# # ECS
# #########

# output "ecs_cluster_name" {
#   description = "ECS cluster name"
#   value       = module.ecs.cluster_name
# }

# output "ecs_cluster_arn" {
#   description = "ECS cluster ARN"
#   value       = module.ecs.cluster_arn
# }


#####
# RDS

output "rds_endpoint" {
  description = "RDS instance endpoint (includes port)"
  value       = module.db_rds.db_instance_endpoint
}

output "rds_address" {
  description = "RDS instance address (hostname only, no port)"
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

output "rds_username" {
  description = "Master username for the database"
  value       = module.db_rds.db_instance_username
  sensitive   = true
}

# RDS Resource Identifiers
output "rds_instance_id" {
  description = "RDS instance ID"
  value       = module.db_rds.db_instance_identifier
}