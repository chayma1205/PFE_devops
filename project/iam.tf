module "iam_bastion" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name                    = "${var.vpc_name}-bastion_role"
  use_name_prefix         = false
  create_instance_profile = true
  description             = "This role is for Bastion instance"

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = ["sts:AssumeRole"]
      principals = [
        {
          type        = "Service"
          identifiers = ["ec2.amazonaws.com"]
        }
      ]
    }
  }

  policies = {
    AWSSecretsManagerClientReadOnlyAccess = "arn:aws:iam::aws:policy/AWSSecretsManagerClientReadOnlyAccess"
  }
}