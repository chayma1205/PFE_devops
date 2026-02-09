terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "us-east-1"
  access_key = "AKIA2UC3C6OMYM66CXNB"
  secret_key = "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"
}
