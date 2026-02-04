output "vpc_id" {
  description = "the id of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "the cidr block of the VPC"
  value       = aws_vpc.main.cidr_block
}