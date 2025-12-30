# Project Context

## Project Overview
This is a DevOps demo project that demonstrates infrastructure as code using Terraform for AWS resources.
I'm a devops/cloud engineer that had a very long break from work and I'm trying to refresh my memory and infrastructure as code skills by creating a personal demo project on AWS using terraform.
This project is for my personal use but it should immitate production-level ready architecture but without any redundant hyper-scaling features, to save personal costs.

## Project Structure
```
terraform/
├── modules/                    # Reusable Terraform modules
│   ├── vpc/                   # VPC with public/private subnets, NAT gateway, IGW
│   ├── eks/                   # EKS cluster and node groups
│   ├── iam-roles/             # IAM roles for EKS cluster and node groups
│   ├── security-groups/       # Security groups for EKS components
│   └── s3-bucket/             # S3 bucket module (used for terraform state)
└── envs/                      # Environment-specific configurations
    └── prod/                  # Production environment
        ├── backend.tf         # S3 backend configuration
        ├── providers.tf       # AWS provider and version constraints
        └── main.tf            # Main configuration calling all modules
```

## Terraform Architecture
- **Modules**: Self-contained, reusable infrastructure components with all necessary variables
- **Environments**: Environment-specific implementations that call modules with minimal, essential variables only
- **Design Principles**:
  - Keep configurations thin and minimal
  - Use `locals` for computed/reusable values, not variables.tf when not needed
  - Consistent naming with prefix pattern: `${local.prefix}resource-name`
  - Only include essential variables at the environment level
  - Modules should be flexible and accept all possible configuration options
  - Separation of concerns: different modules for different AWS resource types
  - Cost-conscious design (single NAT gateway, destroy/recreate workflow)

## Current State
The project currently includes:
- **VPC Module**: Custom VPC with 3 public and 3 private subnets across 3 AZs, single NAT gateway, Internet gateway, EKS-ready tags
- **IAM Roles Module**: EKS cluster and node group IAM roles with AWS managed policies
- **Security Groups Module**: Security groups for EKS cluster and worker nodes
- **EKS Module**: EKS cluster (v1.34) with managed node groups, essential add-ons (VPC-CNI, CoreDNS, kube-proxy)
- **S3 Bucket Module**: General-purpose S3 bucket module
- **Remote State**: S3 backend with DynamoDB locking (resources exist but managed outside Terraform)
- **Region**: ca-west-1 (Calgary)
- **Prefix**: jack-devops-

## Infrastructure Details
- **Kubernetes Version**: 1.34 (latest supported by AWS EKS)
- **VPC CIDR**: 10.0.0.0/16
- **Availability Zones**: ca-west-1a, ca-west-1b, ca-west-1c
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
- **Private Subnets**: 10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24
- **NAT Gateways**: 1 (cost optimization)
- **Node Group**: 2 t3.medium instances (min: 1, max: 4), ON_DEMAND capacity

## Project Goals
I need to have a complete AWS Infrastructure as code solution for hosting a highly available application on EKS with multiple nodes, different services, monitoring, etc.
I need this project to be built step by step in purpose of learning, but at the end this project should be fine-tuned and presentable at a tech interview.

## Next Steps
- Deploy and test the EKS infrastructure
- Add monitoring and logging capabilities
- Implement application workloads on EKS
- Add CI/CD pipeline integration
- Cost optimization and cleanup automation
