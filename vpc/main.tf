terraform {
  required_version = ">= 1.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.30"
    }
  }

  backend "s3" {
    bucket         = "lamis-devops-tfstate-20260225"      
    key            = "vpc/terraform.tfstate"              
    region         = "us-east-1"
    dynamodb_table = "lamis-tfstate-locks"                
    encrypt        = true                                
  }
}
provider "aws" {
  region = var.aws_region
}

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.private_subnets_cidrs
  public_subnets  = var.public_subnets_cidrs

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_suffix  = "pub"
  private_subnet_suffix = "prv"

  igw_tags = {
    Name = "${var.vpc_name}-igw"
  }

  public_route_table_tags = {
    Name = "${var.vpc_name}-public-rt"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
//bastion- small EC2 in public subnet

# Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "${var.vpc_name}-bastion-sg"
  description = "Allow SSH inbound from my IP only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["197.14.236.127/32"]   
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-bastion-sg"
  }
}
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion-ssm-profile"
  role = aws_iam_role.bastion_ssm_role.name
}

resource "aws_iam_role" "bastion_ssm_role" {
  name = "bastion-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
} 

# Bastion EC2 instance
resource "aws_instance" "bastion" {
  ami = data.aws_ssm_parameter.al2023_ami.value 
  instance_type               = "t3.micro"                
  subnet_id                   = module.vpc.public_subnets[0]  
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = "lamis-bastion-key"                   

  user_data = <<-EOF
              #!/bin/bash
              echo "Bastion ready - $(date)" > /var/log/bastion-init.log
              EOF

  tags = {
    Name = "${var.vpc_name}-bastion"
    Environment = var.environment
  }
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name
}

///AKIAYS2NQWV7H4MPANJ3

//GwquFvxbxtIJVsnS6R0tCf17E3OkHyjE0ECLakS/