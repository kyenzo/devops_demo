resource "aws_dynamodb_table" "terraform_locks" {
  name         = "devops-demo-terraform-locks"
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

# Uncomment after creating the S3 bucket and DynamoDB table
# terraform {
#   backend "s3" {
#     bucket         = "devops-demo-terraform-state"
#     key            = "prod/terraform.tfstate"
#     region         = "ca-west-1"
#     encrypt        = true
#     dynamodb_table = "devops-demo-terraform-locks"
#   }
# }
