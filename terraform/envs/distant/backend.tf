terraform {
  backend "s3" {
    bucket         = "jack-devops-terraform-state"
    key            = "distant/terraform.tfstate"
    region         = "ca-west-1"
    dynamodb_table = "jack-devops-terraform-locks"
    encrypt        = true
  }
}
