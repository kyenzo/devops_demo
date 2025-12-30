variable "namespace" {
  description = "Namespace to install ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Version of ArgoCD Helm chart to install"
  type        = string
  default     = "7.8.1"  # Corresponds to ArgoCD v2.13.0
}

variable "repository_url" {
  description = "Git repository URL for ArgoCD to watch"
  type        = string
  default     = "https://github.com/kyenzo/devops_demo.git"
}

variable "target_revision" {
  description = "Git branch/tag for ArgoCD applications"
  type        = string
  default     = "HEAD"
}

variable "enable_root_app" {
  description = "Deploy root application for App-of-Apps pattern"
  type        = bool
  default     = true
}

variable "enable_platform_project" {
  description = "Deploy platform ArgoCD project"
  type        = bool
  default     = true
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint (used for dependency)"
  type        = string
}
