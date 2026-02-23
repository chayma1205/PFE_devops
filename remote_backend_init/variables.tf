#########
# REMOTE STATE
#########

variable "state_bucket_name" {
  type        = string
  description = "The remote state S3 bucket name, must be globally unique"
}

variable "dynamodb_table_name" {
  type        = string
  description = "The name of dynamoDB table to hold the state locking"
  default     = "state_lock"
}

