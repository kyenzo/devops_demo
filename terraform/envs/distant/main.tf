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
  # Step 3: After prod creates peering connection, fill in prod_peering_connection_id above
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

module "iam_roles" {
  source = "../../modules/iam-roles"

  create_eks_cluster_role    = true
  create_eks_node_group_role = true

  eks_cluster_role_name    = "${local.prefix}distant-eks-cluster-role"
  eks_node_group_role_name = "${local.prefix}distant-eks-node-group-role"

  tags = {
    Environment = "distant"
    ManagedBy   = "terraform"
    Project     = "eks-demo"
  }
}

module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id = module.vpc.vpc_id

  create_eks_cluster_sg = true
  create_eks_nodes_sg   = true

  eks_cluster_sg_name = "${local.prefix}distant-eks-cluster-sg"
  eks_nodes_sg_name   = "${local.prefix}distant-eks-nodes-sg"

  tags = {
    Environment = "distant"
    ManagedBy   = "terraform"
    Project     = "eks-demo"
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "${local.prefix}distant-eks-cluster"
  cluster_version = "1.34"

  # IAM roles
  cluster_role_arn    = module.iam_roles.eks_cluster_role_arn
  node_group_role_arn = module.iam_roles.eks_node_group_role_arn

  # Security groups
  cluster_security_group_ids = [module.security_groups.eks_cluster_security_group_id]

  # Networking
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # Node group - smaller than prod since this is for CDN demo only
  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"
  desired_size   = 2
  min_size       = 1
  max_size       = 3
  disk_size      = 20

  # API endpoint access
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["0.0.0.0/0"]

  # Admin access - same AWS account
  admin_access_principal_arn = "arn:aws:iam::449873021552:root"

  # Enable essential add-ons
  enable_vpc_cni_addon    = true
  enable_coredns_addon    = true
  enable_kube_proxy_addon = true

  tags = {
    Environment = "distant"
    ManagedBy   = "terraform"
    Project     = "eks-demo"
  }
}

# Ingress-nginx — creates the internet-facing NLB for the distant cluster
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.11.3"
  namespace        = "ingress-nginx"
  create_namespace = true
  wait             = true

  values = [file("${path.root}/../../../helm/ingress-nginx/values.yaml")]

  depends_on = [module.eks]
}

# Read NLB hostname from the ingress-nginx controller service status
data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.ingress_nginx]
}
