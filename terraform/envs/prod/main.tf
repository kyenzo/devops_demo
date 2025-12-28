locals {
  prefix = "jack-devops-"

  # VPC configuration
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["ca-west-1a", "ca-west-1b", "ca-west-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  # EKS configuration
  cluster_name    = "${local.prefix}eks-cluster"
  cluster_version = "1.34"
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

module "iam_roles" {
  source = "../../modules/iam-roles"

  create_eks_cluster_role   = true
  create_eks_node_group_role = true

  eks_cluster_role_name   = "${local.prefix}eks-cluster-role"
  eks_node_group_role_name = "${local.prefix}eks-node-group-role"

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = "eks-demo"
  }
}

module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id = module.vpc.vpc_id

  create_eks_cluster_sg = true
  create_eks_nodes_sg   = true

  eks_cluster_sg_name = "${local.prefix}eks-cluster-sg"
  eks_nodes_sg_name   = "${local.prefix}eks-nodes-sg"

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = "eks-demo"
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  # IAM roles
  cluster_role_arn     = module.iam_roles.eks_cluster_role_arn
  node_group_role_arn  = module.iam_roles.eks_node_group_role_arn

  # Security groups
  cluster_security_group_ids = [module.security_groups.eks_cluster_security_group_id]

  # Networking
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # Node group configuration
  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"
  desired_size   = 2
  min_size       = 1
  max_size       = 4
  disk_size      = 20

  # API endpoint access
  endpoint_private_access = true
  endpoint_public_access  = true

  # Enable essential add-ons
  enable_vpc_cni_addon      = true
  enable_coredns_addon      = true
  enable_kube_proxy_addon   = true

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = "eks-demo"
  }
}

