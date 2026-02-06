module "vpc" {
  source = "./modules/custom-vpc"

  name            = "custom"
  cidr            = "10.0.0.0/16"
  azs             = ["us-east-2a", "us-east-2b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}