resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${local.prefix}terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "prod"
    Purpose     = "terraform-state-locking"
  }
}

terraform {
  backend "s3" {
    bucket         = "jack-devops-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "ca-west-1"
    encrypt        = true
    dynamodb_table = "jack-devops-terraform-locks"
  }
}
