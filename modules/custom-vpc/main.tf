resource "aws_vpc" "vpc" {
    cidr_block = var.cidr
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = merge(
        {Name = local.prefixed_name},
        var.tags
    )
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id

    tags = merge(
        {Name = "${local.prefixed_name}-igw"},
        var.tags
    )
}

resource "aws_subnet" "public" {
    count = length(var.public_subnets)

    vpc_id = aws_vpc.vpc.id
    cidr_block = var.public_subnets[count.index]
    availability_zone = var.azs[count.index]
    map_public_ip_on_launch = true

    tags = merge(
        {Name = "${local.prefixed_name}-public-${count.index + 1}"},
        {Type = "public"},
        var.tags
    )
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = merge(
        {Name = "${local.prefixed_name}-pulic-rt"},
        var.tags
    )
}

resource "aws_route_table_association" "public" {
    count = length(var.public_subnets)

    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat_eip" {
    count = var.enable_nat_gateway ? 1 : 0
    domain = "vpc"

    tags = merge(
        {Name = "${local.prefixed_name}-nat-eip"},
        var.tags
    )
}

resource "aws_nat_gateway" "nat_gw" {
    count = var.enable_nat_gateway ? 1 : 0
    allocation_id = aws_eip.nat_eip[0].id
    subnet_id = aws_subnet.public[0].id

    tags = merge(
        {Name = "${local.prefixed_name}-nat-gw"},
        var.tags
    )

    depends_on = [ aws_internet_gateway.igw ]
}

resource "aws_subnet" "private" {
    count = length(var.private_subnets)

    vpc_id = aws_vpc.vpc.id
    cidr_block = var.private_subnets[count.index]
    availability_zone = var.azs[count.index]
    map_public_ip_on_launch = true

    tags = merge(
        {Name = "${local.prefixed_name}-private-${count.index + 1}"},
        {Type = "private"},
        var.tags
    )
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.vpc.id

    dynamic "route" {
      for_each = var.enable_nat_gateway ? [1] : []
      content {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gw[0].id
      }
    }

    tags = merge(
        {Name = "${local.prefixed_name}-private-rt"},
        var.tags
    )
}

resource "aws_route_table_association" "private" {
    count = length(var.private_subnets)

    subnet_id = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id
}