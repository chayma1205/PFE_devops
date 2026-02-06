output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "public_rt_id" {
  value = aws_route_table.public.id
}

output "private_rt_id" {
  value = aws_route_table.private.id
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}