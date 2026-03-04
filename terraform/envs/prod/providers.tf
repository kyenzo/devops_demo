terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ca-west-1"
}

# Provider for managing resources in the distant cluster's region
provider "aws" {
  alias  = "distant"
  region = "ap-southeast-1"
}

# Data source to get prod EKS cluster auth token
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

# Auth token for distant cluster (endpoint + CA come from terraform_remote_state.distant in main.tf)
data "aws_eks_cluster_auth" "distant" {
  provider = aws.distant
  name     = "jack-devops-distant-eks-cluster"
}

# Helm provider for prod cluster (ArgoCD + ingress-nginx)
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Helm provider for distant cluster (ingress-nginx)
provider "helm" {
  alias = "distant"
  kubernetes {
    host                   = data.terraform_remote_state.distant.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.distant.outputs.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.distant.token
  }
}

# Kubernetes provider for reading service status from prod cluster
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Kubernetes provider for reading service status from distant cluster
provider "kubernetes" {
  alias                  = "distant"
  host                   = data.terraform_remote_state.distant.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.distant.outputs.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.distant.token
}

# kubectl provider for applying ArgoCD manifests
provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}
