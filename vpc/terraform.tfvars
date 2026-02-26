aws_region = "us-east-1"

environment = "dev"                

vpc_name    = "lamis-dev-vpc"

vpc_cidr    = "10.0.0.0/16"

vpc_azs = ["us-east-1a", "us-east-1b"]

public_subnets_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]
private_subnets_cidrs = [
  "10.0.11.0/24",
  "10.0.12.0/24"
]

enable_dns_support   = true
enable_dns_hostnames = true