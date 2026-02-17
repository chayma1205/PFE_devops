terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.30"
    }
  }

  required_version = ">= 1.1"
}

provider "aws" {
  region = "us-east-1"
  access_key = "AKIA6GBMCFQYBFKQEVK7"
  secret_key = "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"

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}