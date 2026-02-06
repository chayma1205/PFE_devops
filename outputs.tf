output "vpc_id" {
  description = "the id of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of ids of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of ids of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_route_table_ids" {
  description = "List of ids of public route tables"
  value       = module.vpc.public_rt_id
}

output "private_route_table_ids" {
  description = "List of ids of private route tables"
  value       = module.vpc.private_rt_id
}

output "igw_id" {
  description = "the id of the Internet Gateway"
  value       = module.vpc.igw_id
}