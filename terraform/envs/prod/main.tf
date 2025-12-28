locals {
  prefix = "jack-devops-"
}

module "terraform_state_bucket" {
  source = "../../modules/s3-bucket"

  bucket_name         = "${local.prefix}terraform-state"
  versioning_enabled  = true
  block_public_access = true

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "prod"
    Purpose     = "terraform-state"
  }
}

