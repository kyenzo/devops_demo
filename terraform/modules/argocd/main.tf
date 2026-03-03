# ArgoCD Terraform Module
# Automatically deploys ArgoCD to EKS cluster using Helm

# Add ArgoCD Helm repository
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = var.namespace
  create_namespace = true

  # Use values from helm/argocd/
  values = [
    file("${path.module}/../../../helm/argocd/values.yaml"),
    file("${path.module}/../../../helm/argocd/values-prod.yaml")
  ]

  # IRSA: annotate service accounts so pods can assume the IAM role
  dynamic "set" {
    for_each = var.irsa_role_arn != "" ? [var.irsa_role_arn] : []
    content {
      name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = set.value
    }
  }

  dynamic "set" {
    for_each = var.irsa_role_arn != "" ? [var.irsa_role_arn] : []
    content {
      name  = "server.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = set.value
    }
  }

  dynamic "set" {
    for_each = var.irsa_role_arn != "" ? [var.irsa_role_arn] : []
    content {
      name  = "applicationSet.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = set.value
    }
  }

  # Wait for ArgoCD to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  # Ensure cluster is ready before installing
  depends_on = [var.cluster_endpoint]
}

# Create root application for App-of-Apps pattern
resource "kubectl_manifest" "root_app" {
  count = var.enable_root_app ? 1 : 0

  yaml_body = file("${path.module}/../../../helm/apps/root-app.yaml")

  depends_on = [helm_release.argocd]
}
