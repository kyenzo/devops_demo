module "terraform_state_bucket" {
  source = "../../modules/s3-bucket"

  bucket_name         = var.state_bucket_name
  versioning_enabled  = true
  block_public_access = true

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "prod"
    Purpose     = "terraform-state"
  }
}

# module "loadbalancer" {
#   source = "../../modules/loadbalancer"

#   name            = var.lb_name
#   security_groups = var.security_groups
#   subnets         = var.subnets
#   vpc_id          = var.vpc_id
# }
