# Data source for current AWS account
data "aws_caller_identity" "current" {}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster" {
  count = var.create_eks_cluster_role ? 1 : 0

  name = var.eks_cluster_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count = var.create_eks_cluster_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster[0].name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  count = var.create_eks_cluster_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster[0].name
}

# EKS Node Group IAM Role
resource "aws_iam_role" "eks_node_group" {
  count = var.create_eks_node_group_role ? 1 : 0

  name = var.eks_node_group_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  count = var.create_eks_node_group_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group[0].name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  count = var.create_eks_node_group_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group[0].name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  count = var.create_eks_node_group_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group[0].name
}

# EKS Cluster Admin Access Role
resource "aws_iam_role" "eks_admin" {
  count = var.create_eks_admin_role ? 1 : 0

  name = var.eks_admin_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        # Allow specific principals OR all IAM users in the account
        AWS = length(var.eks_admin_role_principals) > 0 ? var.eks_admin_role_principals : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }
    }]
  })

  tags = var.tags
}

# Inline policy for EKS admin to describe cluster
resource "aws_iam_role_policy" "eks_admin_describe_cluster" {
  count = var.create_eks_admin_role ? 1 : 0

  name = "eks-describe-cluster"
  role = aws_iam_role.eks_admin[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ]
      Resource = "*"
    }]
  })
}
