variable "create_eks_cluster_role" {
  description = "Whether to create EKS cluster IAM role"
  type        = bool
  default     = true
}

variable "eks_cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  type        = string
}

variable "create_eks_node_group_role" {
  description = "Whether to create EKS node group IAM role"
  type        = bool
  default     = true
}

variable "eks_node_group_role_name" {
  description = "Name of the EKS node group IAM role"
  type        = string
}

variable "tags" {
  description = "Tags to apply to IAM roles"
  type        = map(string)
  default     = {}
}
