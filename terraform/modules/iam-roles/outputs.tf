output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = try(aws_iam_role.eks_cluster[0].arn, null)
}

output "eks_cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = try(aws_iam_role.eks_cluster[0].name, null)
}

output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = try(aws_iam_role.eks_node_group[0].arn, null)
}

output "eks_node_group_role_name" {
  description = "Name of the EKS node group IAM role"
  value       = try(aws_iam_role.eks_node_group[0].name, null)
}
