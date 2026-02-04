output "vpc_id" {
  description = "the id of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "the cidr block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_1_cidr" {
  description = "cidr block of the public subnet"
  value       = aws_subnet.public_1.cidr_block
}