terraform {
  backend "s3" {
    bucket         = "jack-devops-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "ca-west-1"
    encrypt        = true
    dynamodb_table = "jack-devops-terraform-locks"
  }
}
