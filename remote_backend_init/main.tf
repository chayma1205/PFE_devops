module "remote_state_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.10.0"

  bucket           = var.state_bucket_name
  object_ownership = "BucketOwnerEnforced"
  force_destroy    = false

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning = {
    enabled = true
  }
}

module "remote_state_locking" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.0"

  name                        = var.dynamodb_table_name
  hash_key                    = "LockID"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = true # prevent accidential deletion
  table_class                 = "STANDARD"

  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]
}