variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "create_eks_cluster_sg" {
  description = "Whether to create EKS cluster security group"
  type        = bool
  default     = true
}

variable "eks_cluster_sg_name" {
  description = "Name of the EKS cluster security group"
  type        = string
}

variable "create_eks_nodes_sg" {
  description = "Whether to create EKS nodes security group"
  type        = bool
  default     = false
}

variable "eks_nodes_sg_name" {
  description = "Name of the EKS nodes security group"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to security groups"
  type        = map(string)
  default     = {}
}
