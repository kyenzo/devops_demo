output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = helm_release.argocd.namespace
}

output "argocd_release_name" {
  description = "Helm release name for ArgoCD"
  value       = helm_release.argocd.name
}

output "argocd_version" {
  description = "ArgoCD chart version installed"
  value       = helm_release.argocd.version
}

output "argocd_status" {
  description = "Status of ArgoCD Helm release"
  value       = helm_release.argocd.status
}
