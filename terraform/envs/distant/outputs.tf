output "vpc_id" {
  description = "Distant VPC ID - needed for prod peering (Step 2)"
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

output "cluster_endpoint" {
  description = "EKS cluster endpoint - needed to register cluster in ArgoCD"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster CA data - needed to register cluster in ArgoCD"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "ingress_nlb_hostname" {
  description = "Distant NLB hostname - read by prod env to configure CloudFront failover origin"
  value       = data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname
}
