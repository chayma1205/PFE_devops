output "vpc_id" {
  description = "the id of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "the cidr block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "List of ids of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "List of ids of private subnets"
  value       = module.vpc.private_subnets
}

output "public_route_table_ids" {
  description = "List of ids of public route tables"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "List of ids of private route tables"
  value       = module.vpc.private_route_table_ids
}

output "igw_id" {
  description = "the id of the Internet Gateway"
  value       = module.vpc.igw_id
}