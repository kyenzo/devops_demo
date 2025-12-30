variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for the EKS cluster"
  type        = string
}

variable "node_group_role_arn" {
  description = "ARN of the IAM role for the EKS node group"
  type        = string
}

variable "cluster_security_group_ids" {
  description = "List of security group IDs for the EKS cluster"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the EKS control plane"
  type        = list(string)
  default     = []
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "Type of capacity for the node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 20
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "enable_vpc_cni_addon" {
  description = "Enable VPC CNI addon"
  type        = bool
  default     = true
}

variable "enable_coredns_addon" {
  description = "Enable CoreDNS addon"
  type        = bool
  default     = true
}

variable "enable_kube_proxy_addon" {
  description = "Enable kube-proxy addon"
  type        = bool
  default     = true
}

variable "admin_access_principal_arn" {
  description = "ARN of IAM principal (user, role, or root) to grant admin access to the EKS cluster"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
