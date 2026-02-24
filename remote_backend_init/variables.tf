#########
# REMOTE STATE
#########

variable "aws_region" {
  type        = string
  description = "The region for the provisioned aws s3 and DynamoDB"
  default     = "us-east-1"
}


variable "state_bucket_name" {
  type        = string
  description = "The remote state S3 bucket name, must be globally unique"
}

variable "dynamodb_table_name" {
  type        = string
  description = "The name of dynamoDB table to hold the state locking"
  default     = "state_lock"
}

