output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = try(aws_security_group.eks_cluster[0].id, null)
}

output "eks_nodes_security_group_id" {
  description = "ID of the EKS nodes security group"
  value       = try(aws_security_group.eks_nodes[0].id, null)
}
