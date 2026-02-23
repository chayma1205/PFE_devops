terraform {
  backend "s3" {
    bucket         = "maissen-belgacem2"
    key            = "state"
    region         = "us-east-2"
    dynamodb_table = "state_lock"
    use_lockfile   = true
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.30"
    }
  }

  required_version = ">= 1.1"
}
