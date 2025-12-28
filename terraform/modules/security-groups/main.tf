# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  count = var.create_eks_cluster_sg ? 1 : 0

  name        = var.eks_cluster_sg_name
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = var.eks_cluster_sg_name
    }
  )
}

# Optional: Additional security group for worker nodes
resource "aws_security_group" "eks_nodes" {
  count = var.create_eks_nodes_sg ? 1 : 0

  name        = var.eks_nodes_sg_name
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = var.eks_nodes_sg_name
    }
  )
}

# Allow nodes to communicate with cluster API
resource "aws_security_group_rule" "cluster_to_nodes" {
  count = var.create_eks_cluster_sg && var.create_eks_nodes_sg ? 1 : 0

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster[0].id
  security_group_id        = aws_security_group.eks_nodes[0].id
  description              = "Allow cluster API to communicate with nodes"
}

# Allow nodes to communicate with each other
resource "aws_security_group_rule" "nodes_internal" {
  count = var.create_eks_nodes_sg ? 1 : 0

  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.eks_nodes[0].id
  description       = "Allow nodes to communicate with each other"
}
