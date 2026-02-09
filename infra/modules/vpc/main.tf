//vpc
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = { Name = var.vpc_name }
}
//ig
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = { Name = "${var.vpc_name}-igw" }
}
//public subnets
resource "aws_subnet" "public" {
  for_each =  {
    for index, cidr in var.public_subnets :
    cidr => {
      az = var.azs[index]
    }
  }
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.key
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = { Name = "public-${each.value.az}" }
}
//private subnets

resource "aws_subnet" "private" {
  for_each =  {
    for index, cidr in var.private_subnets :
    cidr => {
      az = var.azs[index]
    }
  }
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.key
  availability_zone       = each.value.az
  tags = { Name = "private-${each.value.az}" }
}
//nat
resource "aws_eip" "nat" {
  domain = "vpc"
}
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id

  depends_on = [aws_internet_gateway.igw]
}
//route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

