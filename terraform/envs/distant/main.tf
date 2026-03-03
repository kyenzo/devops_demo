locals {
  prefix = "jack-devops-"

  # VPC configuration - non-overlapping with prod (10.0.0.0/16)
  vpc_cidr             = "10.1.0.0/16"
  availability_zones   = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]

  # VPC Peering - Step 3: Fill in after prod env creates the peering connection
  # Run: cd ../prod && terraform output vpc_peering_connection_id
  prod_peering_connection_id = null # e.g. "pcx-0abc123"
  prod_vpc_cidr              = "10.0.0.0/16"
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_name           = "${local.prefix}distant-vpc"
  vpc_cidr           = local.vpc_cidr
  availability_zones = local.availability_zones

  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs

  create_internet_gateway = true
  create_nat_gateway      = true
  nat_gateway_count       = 1

  # VPC Peering - Accepter side
  # Step 3: After prod creates peering connection, fill in prod_peering_connection_id above and set accept_peering_connection = true
  accept_peering_connection = local.prod_peering_connection_id != null
  peering_connection_id     = local.prod_peering_connection_id
  peer_vpc_cidr             = local.prod_vpc_cidr

  tags = {
    Environment = "distant"
    ManagedBy   = "terraform"
    Project     = "eks-demo"
    Region      = "ap-southeast-1"
  }
}

output "vpc_id" {
  description = "ID of the distant VPC - needed for prod peering connection"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}
