data "aws_caller_identity" "current" {}

locals {
  prefix = "jack-devops-"

  # VPC configuration
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["ca-west-1a", "ca-west-1b", "ca-west-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  # VPC Peering - Step 2: Fill in after distant env is applied
  # Run: cd ../distant && terraform output vpc_id
  distant_vpc_id   = null # e.g. "vpc-0abc123"
  distant_vpc_cidr = "10.1.0.0/16"
  distant_region   = "ap-southeast-1"

  # Construct ARN from known values so it is resolved at plan time,
  # avoiding the Helm provider "inconsistent final plan" bug with dynamic set blocks
  argocd_irsa_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}argocd-irsa-role"
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

  # VPC Peering - Requester side
  # Step 2: After applying distant env, fill in distant_vpc_id above and set create_peering_connection = true
  create_peering_connection = local.distant_vpc_id != null
  peer_vpc_id               = local.distant_vpc_id
  peer_vpc_cidr             = local.distant_vpc_cidr
  peer_region               = local.distant_region

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = "eks-demo"
  }
}

module "iam_roles" {
  source = "../../modules/iam-roles"

  create_eks_cluster_role    = true
  create_eks_node_group_role = true

  eks_cluster_role_name    = "${local.prefix}eks-cluster-role"
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

  cluster_name    = "${local.prefix}eks-cluster"
  cluster_version = "1.34"

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
  instance_types = ["t3.large"]
  capacity_type  = "ON_DEMAND"
  desired_size   = 2
  min_size       = 1
  max_size       = 4
  disk_size      = 20

  # API endpoint access
  endpoint_private_access = true
  endpoint_public_access  = true  # Public access enabled but restricted by CIDR and IAM
  public_access_cidrs     = ["0.0.0.0/0"]  # Replace with your IP: ["YOUR_IP/32"]

  # Admin access - grant root account direct access to the cluster (RBAC via EKS Access Entries)
  admin_access_principal_arn = "arn:aws:iam::449873021552:root"

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

# IRSA: OIDC provider for prod EKS cluster
data "tls_certificate" "eks_oidc" {
  url = module.eks.cluster_oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = module.eks.cluster_oidc_issuer_url

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = "eks-demo"
  }
}

# IRSA: IAM role for ArgoCD service accounts
data "aws_iam_policy_document" "argocd_irsa_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringLike"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:argocd:argocd-application-controller",
        "system:serviceaccount:argocd:argocd-server",
        "system:serviceaccount:argocd:argocd-applicationset-controller",
      ]
    }
  }
}

resource "aws_iam_role" "argocd_irsa" {
  name               = "${local.prefix}argocd-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.argocd_irsa_trust.json

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = "eks-demo"
  }
}

resource "aws_iam_role_policy" "argocd_eks_access" {
  name = "argocd-eks-access"
  role = aws_iam_role.argocd_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster"]
      Resource = "*"
    }]
  })
}

# IRSA: Grant ArgoCD IAM role cluster-admin access to the distant EKS cluster
resource "aws_eks_access_entry" "argocd_distant" {
  provider = aws.distant

  cluster_name  = "jack-devops-distant-eks-cluster"
  principal_arn = local.argocd_irsa_role_arn
  type          = "STANDARD"

  tags = {
    Environment = "distant"
    ManagedBy   = "terraform"
    Project     = "eks-demo"
  }
}

resource "aws_eks_access_policy_association" "argocd_distant_admin" {
  provider = aws.distant

  cluster_name  = "jack-devops-distant-eks-cluster"
  principal_arn = local.argocd_irsa_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.argocd_distant]
}

# Read distant cluster outputs - apply distant env first before prod
data "terraform_remote_state" "distant" {
  backend = "s3"
  config = {
    bucket = "jack-devops-terraform-state"
    key    = "distant/terraform.tfstate"
    region = "ca-west-1"
  }
}

# Register distant cluster in ArgoCD by creating a cluster secret
# ArgoCD uses awsAuthConfig for EKS clusters - no static credentials needed
resource "kubectl_manifest" "argocd_distant_cluster" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "cluster-distant"
      namespace = "argocd"
      labels = {
        "argocd.argoproj.io/secret-type" = "cluster"
      }
    }
    stringData = {
      name   = "distant"
      server = data.terraform_remote_state.distant.outputs.cluster_endpoint
      config = jsonencode({
        awsAuthConfig = {
          clusterName = "jack-devops-distant-eks-cluster"
        }
        tlsClientConfig = {
          insecure = false
          caData   = data.terraform_remote_state.distant.outputs.cluster_certificate_authority_data
        }
      })
    }
  })

  depends_on = [module.argocd]
}

module "argocd" {
  source = "../../modules/argocd"

  # Dependency on EKS cluster
  cluster_endpoint = module.eks.cluster_endpoint

  # ArgoCD configuration
  repository_url  = "https://github.com/kyenzo/devops_demo.git"
  target_revision = "master"  # Only monitor master branch for production

  # Enable GitOps components
  enable_root_app = true

  # IRSA: allow ArgoCD to authenticate to remote EKS clusters
  irsa_role_arn = local.argocd_irsa_role_arn

  # Module depends on EKS being fully ready
  depends_on = [
    module.eks,
    aws_iam_role.argocd_irsa,
  ]
}

# Ingress-nginx on prod cluster — creates the internet-facing NLB
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

# Ingress-nginx on distant cluster — creates the internet-facing NLB in ap-southeast-1
resource "helm_release" "ingress_nginx_distant" {
  provider = helm.distant

  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.11.3"
  namespace        = "ingress-nginx"
  create_namespace = true
  wait             = true

  values = [file("${path.root}/../../../helm/ingress-nginx/values.yaml")]
}

# Read NLB hostname from the ingress-nginx controller service status on prod cluster
data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.ingress_nginx]
}

# Read NLB hostname from the ingress-nginx controller service status on distant cluster
data "kubernetes_service" "ingress_nginx_distant" {
  provider = kubernetes.distant

  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.ingress_nginx_distant]
}

module "cdn" {
  source = "../../modules/cloudfront"

  prod_origin_domain    = data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname
  distant_origin_domain = data.kubernetes_service.ingress_nginx_distant.status[0].load_balancer[0].ingress[0].hostname

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = "eks-demo"
  }
}
