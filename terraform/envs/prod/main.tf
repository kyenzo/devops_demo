locals {
  prefix = "jack-devops-"

  # VPC configuration
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["ca-west-1a", "ca-west-1b", "ca-west-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_name           = "${local.prefix}eks-vpc"
  vpc_cidr           = local.vpc_cidr
  availability_zones = local.availability_zones

  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs

  create_internet_gateway = true
  create_nat_gateway      = true
  nat_gateway_count       = 1  # Cost-saving: 1 NAT gateway instead of 3

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = "eks-demo"
  }
}

