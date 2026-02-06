variable "name" {
  type        = string
  description = "name prefix for the vpc resources"
}

variable "cidr" {
  type = string
  description = "the cidr block for the vpc"
}

variable "azs" {
  type = list(string)
  description = "availability zones"
}

variable "public_subnets" {
  type = list(string)
  description = "public subnets cidr blcoks"

  validation {
    condition = length(var.public_subnets) <= length(var.azs)
    error_message = "the number of public_subnets must not exceed match the number of azs"
  }
}

variable "private_subnets" {
  type = list(string)
  description = "private subnets cidr blocks"

  validation {
    condition = length(var.private_subnets) <= length(var.azs)
    error_message = "the number of private_subnets must not exceed the number of azs"
  }
}

variable "enable_nat_gateway" {
  type = bool
  description = "whether or not to enable nat gw"
  default = true
}

variable "tags" {
  type = map(string)
  description = "tags to attach to vpc resources"
  default = {}
}