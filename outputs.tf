output "vpc_id" {
  description = "the id of the vpc"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "list of ids of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "list of ids of private subnets"
  value       = module.vpc.private_subnets
}

output "asg_names" {
  description = "list of autoscaling group names"
  value       = module.asg[*].autoscaling_group_name
}

output "asg_arns" {
  description = "list of arns for the autoscaling groups"
  value       = module.asg[*].autoscaling_group_arn
}

output "asg_ids" {
  description = "list of ids for the autoscaling groups"
  value       = module.asg[*].autoscaling_group_id
}

# output "asg_min_sizes" {
#   description = "list of minimum sizes of the autoscaling groups"
#   value       = module.asg[*].autoscaling_group_min_size
# }

# output "asg_max_sizes" {
#   description = "list of maximum sizes of the autoscaling groups"
#   value       = module.asg[*].autoscaling_group_max_size
# }

# output "asg_desired_capacities" {
#   description = "list of desired capacities of the autoscaling groups"
#   value       = module.asg[*].autoscaling_group_desired_capacity
# }

output "asg_launch_template_ids" {
  description = "list of launch template ids used by the autoscaling groups"
  value       = module.asg[*].launch_template_id
}

output "asg_launch_template_latest_versions" {
  description = "list of latest versions of the launch template created by terraform"
  value       = module.asg[*].launch_template_latest_version
}