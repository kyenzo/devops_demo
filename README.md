# DevOps Demo Project - AWS EKS Infrastructure

A production-ready AWS infrastructure demonstration project built with Terraform, showcasing modern DevOps practices and cloud-native architecture patterns.

## Project Overview

This project demonstrates a complete Infrastructure as Code (IaC) solution for deploying a highly available Kubernetes cluster on AWS. Built as a learning and interview preparation project, it follows production-level best practices while maintaining cost efficiency.

### Goals

- Build a complete AWS infrastructure solution for hosting highly available applications on EKS
- Demonstrate proficiency in Terraform, AWS, Kubernetes, and DevOps practices
- Create modular, reusable infrastructure components
- Implement security best practices (RBAC, network isolation, IAM)
- Maintain cost-conscious design suitable for personal use
- Document the learning journey and architecture decisions

## Architecture

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Account                           │
│                                                               │
│  ┌────────────────────────────────────────────────────┐    │
│  │              VPC (10.0.0.0/16)                      │    │
│  │                                                      │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────┐│    │
│  │  │ Public Subnet │  │ Public Subnet │  │  Public   ││    │
│  │  │ 10.0.1.0/24  │  │ 10.0.2.0/24  │  │ Subnet    ││    │
│  │  │   (AZ-a)     │  │   (AZ-b)     │  │ 10.0.3.0/ ││    │
│  │  └──────────────┘  └──────────────┘  └───────────┘│    │
│  │         │                  │                 │      │    │
│  │    ┌────┴──────────────────┴─────────────────┘     │    │
│  │    │         Internet Gateway                      │    │
│  │    └───────────────────────────────────────────────┘    │
│  │                                                      │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────┐│    │
│  │  │Private Subnet│  │Private Subnet│  │  Private  ││    │
│  │  │ 10.0.11.0/24 │  │ 10.0.12.0/24 │  │  Subnet   ││    │
│  │  │   (AZ-a)     │  │   (AZ-b)     │  │ 10.0.13.0/││    │
│  │  └──────────────┘  └──────────────┘  └───────────┘│    │
│  │         │                                           │    │
│  │    ┌────┴────────┐                                 │    │
│  │    │ NAT Gateway │                                 │    │
│  │    └─────────────┘                                 │    │
│  │                                                      │    │
│  │  ┌────────────────────────────────────────────────┐│    │
│  │  │         EKS Cluster (v1.34)                    ││    │
│  │  │                                                 ││    │
│  │  │  ┌──────────────┐  ┌──────────────┐           ││    │
│  │  │  │ Worker Node  │  │ Worker Node  │           ││    │
│  │  │  │  t3.small    │  │  t3.small    │           ││    │
│  │  │  └──────────────┘  └──────────────┘           ││    │
│  │  └────────────────────────────────────────────────┘│    │
│  └────────────────────────────────────────────────────┘    │
│                                                               │
│  ┌────────────────────────────────────────────────────┐    │
│  │              IAM Roles & Policies                   │    │
│  │  - EKS Cluster Role                                 │    │
│  │  - EKS Node Group Role                              │    │
│  │  - EKS Admin Access Role (RBAC)                     │    │
│  └────────────────────────────────────────────────────┘    │
│                                                               │
└─────────────────────────────────────────────────────────────┘

  Remote State Storage:
  ┌─────────────────┐
  │  S3 Bucket      │  terraform state files
  └─────────────────┘
  ┌─────────────────┐
  │ DynamoDB Table  │  state locking
  └─────────────────┘
```

## Project Structure

```
terraform/
├── modules/                      # Reusable infrastructure modules
│   ├── vpc/                     # VPC with subnets, NAT, IGW
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/                     # EKS cluster and node groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam-roles/               # IAM roles for EKS
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security-groups/         # Security groups for EKS
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── s3-bucket/               # S3 bucket module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── envs/                        # Environment configurations
    └── prod/                    # Production environment
        ├── backend.tf           # S3 backend configuration
        ├── providers.tf         # AWS provider setup
        ├── main.tf              # Main configuration
        └── variables.tf         # Environment variables
```

## Terraform Modules

### 1. VPC Module (`modules/vpc`)

Creates a production-ready VPC with high availability across multiple availability zones.

**Features:**
- Custom VPC with configurable CIDR block
- 3 public subnets across 3 availability zones
- 3 private subnets across 3 availability zones
- Internet Gateway for public subnet access
- NAT Gateway for private subnet outbound connectivity (1 gateway for cost optimization)
- Route tables configured for public and private subnets
- EKS-ready subnet tags for automatic discovery

**Resources Created:**
- VPC
- 6 Subnets (3 public, 3 private)
- Internet Gateway
- NAT Gateway (1 for cost efficiency)
- Elastic IP for NAT Gateway
- Route Tables and Associations

### 2. IAM Roles Module (`modules/iam-roles`)

Manages all IAM roles and policies required for EKS cluster operation and access control.

**Features:**
- EKS Cluster Service Role with required AWS managed policies
- EKS Node Group Role with worker node permissions
- EKS Admin Access Role for human access with RBAC
- Automatic trust policy configuration
- Flexible principal assignment

**Resources Created:**
- `eks-cluster-role`: Allows EKS to manage AWS resources
- `eks-node-group-role`: Allows worker nodes to join cluster and pull images
- `eks-admin-role`: Human access role with cluster admin permissions
- Policy attachments for all AWS managed policies
- Custom inline policies for cluster access

### 3. Security Groups Module (`modules/security-groups`)

Configures network security for EKS cluster components.

**Features:**
- EKS Cluster security group
- EKS Node Group security group
- Properly configured ingress/egress rules
- VPC-aware security group rules

**Resources Created:**
- Security group for EKS control plane
- Security group for EKS worker nodes

### 4. EKS Module (`modules/eks`)

Deploys and configures the Amazon EKS cluster with managed node groups.

**Features:**
- EKS cluster with configurable Kubernetes version (currently v1.34)
- Managed node groups with auto-scaling
- Essential EKS add-ons (VPC-CNI, CoreDNS, kube-proxy)
- Modern API-based authentication with EKS Access Entries
- Cluster admin access via IAM roles
- Public and private API endpoint access
- Comprehensive cluster logging

**Resources Created:**
- EKS Cluster
- EKS Managed Node Group
- EKS Add-ons (VPC-CNI, CoreDNS, kube-proxy)
- EKS Access Entry for admin role
- EKS Access Policy Association (Cluster Admin)

### 5. S3 Bucket Module (`modules/s3-bucket`)

General-purpose S3 bucket module for various use cases including Terraform state storage.

**Features:**
- Configurable bucket settings
- Versioning support
- Encryption options
- Lifecycle policies

## Special Features

### 1. RBAC and Access Control

**EKS Access Entries (Modern Authentication)**
- Uses AWS EKS Access Entries API for cluster authentication
- Configured with `API_AND_CONFIG_MAP` authentication mode
- Automatic IAM role to Kubernetes RBAC mapping

**IAM Role-Based Access**
- Dedicated `eks-admin-role` for cluster administration
- Root account can assume admin role by default
- Easily extensible to add more users/roles
- Cluster admin policy provides full Kubernetes permissions

**Access Flow:**
```
User → Assume eks-admin-role → EKS Access Entry → Cluster Admin Permissions
```

### 2. Secure Networking

**Network Isolation:**
- Private subnets for EKS worker nodes (no direct internet access)
- Public subnets for load balancers and bastion hosts
- NAT Gateway for controlled outbound connectivity from private subnets

**Multi-AZ High Availability:**
- Resources distributed across 3 availability zones (ca-west-1a, ca-west-1b, ca-west-1c)
- Automatic failover capability
- Zone-independent operation

**API Endpoint Access:**
- Private endpoint enabled (VPC-internal access)
- Public endpoint configurable (currently enabled for development)
- CIDR-based access restrictions available
- Plan to disable public access and use VPN in production

### 3. Terraform State Management

**Remote State Storage:**
- S3 bucket for centralized state storage
- DynamoDB table for state locking
- Prevents concurrent modifications
- State versioning enabled

**Backend Configuration:**
```hcl
backend "s3" {
  bucket         = "jack-devops-terraform-state"
  key            = "prod/terraform.tfstate"
  region         = "ca-west-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

### 4. Cost Optimization

- Single NAT Gateway instead of 3 (saves ~$64/month)
- t3.small instances for worker nodes (cost-effective)
- Managed node groups (no additional management overhead)
- Resource tagging for cost tracking
- Destroy/recreate workflow for development

### 5. Modular Architecture

**Design Principles:**
- Self-contained modules with clear boundaries
- Minimal coupling between modules
- Reusable across environments
- Variables for all configurable values
- Comprehensive outputs for module chaining

**Benefits:**
- Easy to test individual components
- Simple to add new environments
- Clear separation of concerns
- Maintainable and scalable

## Infrastructure Details

### Current Configuration

| Component | Specification |
|-----------|---------------|
| **Region** | ca-west-1 (Calgary) |
| **Kubernetes Version** | 1.34 |
| **VPC CIDR** | 10.0.0.0/16 |
| **Availability Zones** | 3 (ca-west-1a, ca-west-1b, ca-west-1c) |
| **Public Subnets** | 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24 |
| **Private Subnets** | 10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24 |
| **NAT Gateways** | 1 (cost optimization) |
| **Worker Nodes** | 2 (min: 1, max: 4) |
| **Instance Type** | t3.small |
| **Capacity Type** | ON_DEMAND |
| **Node Disk Size** | 20 GB |

## Getting Started

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Terraform >= 1.0
- kubectl

### Deployment

1. **Initialize Terraform:**
   ```bash
   cd terraform/envs/prod
   terraform init
   ```

2. **Review the plan:**
   ```bash
   terraform plan
   ```

3. **Apply the configuration:**
   ```bash
   terraform apply
   ```

4. **Configure kubectl:**
   ```bash
   aws eks update-kubeconfig --name jack-devops-eks-cluster --region ca-west-1
   ```

5. **Verify cluster access:**
   ```bash
   kubectl get nodes
   ```

### Accessing the Cluster

To access the cluster with admin permissions, assume the eks-admin-role:

```bash
# Get the role ARN
aws iam get-role --role-name jack-devops-eks-admin-role --query 'Role.Arn' --output text

# Assume the role
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/jack-devops-eks-admin-role \
  --role-session-name kubectl-session

# Export the temporary credentials
export AWS_ACCESS_KEY_ID=<AccessKeyId>
export AWS_SECRET_ACCESS_KEY=<SecretAccessKey>
export AWS_SESSION_TOKEN=<SessionToken>

# Update kubeconfig
aws eks update-kubeconfig --name jack-devops-eks-cluster --region ca-west-1

# Verify access
kubectl get nodes
kubectl get pods -A
```

## Development Timeline

### Phase 1: Foundation (Completed)
- [x] S3 bucket module for reusable bucket creation
- [x] Remote state backend setup (S3 + DynamoDB)
- [x] VPC module with public/private subnets
- [x] Multi-AZ networking with NAT gateway

### Phase 2: IAM and Security (Completed)
- [x] IAM roles module for EKS cluster and nodes
- [x] Security groups module for EKS components
- [x] EKS admin access role with RBAC
- [x] Modern EKS Access Entries implementation

### Phase 3: EKS Cluster (Completed)
- [x] EKS cluster module with managed node groups
- [x] Essential EKS add-ons (VPC-CNI, CoreDNS, kube-proxy)
- [x] Cluster logging configuration
- [x] API endpoint access control
- [x] Integration testing and validation

### Phase 4: Future Enhancements (Planned)
- [ ] VPN setup for secure private cluster access
- [ ] Monitoring and logging (Prometheus, Grafana)
- [ ] Application workload deployment
- [ ] Ingress controller (ALB/NGINX)
- [ ] CI/CD pipeline integration
- [ ] Secrets management (AWS Secrets Manager/External Secrets)
- [ ] Auto-scaling configuration (Cluster Autoscaler/Karpenter)
- [ ] Backup and disaster recovery procedures

## Tags and Organization

All resources are tagged with:
- `Environment`: prod
- `ManagedBy`: terraform
- `Project`: eks-demo

## Resource Naming Convention

All resources follow the pattern: `jack-devops-{resource-name}`

Examples:
- `jack-devops-eks-vpc`
- `jack-devops-eks-cluster`
- `jack-devops-eks-cluster-role`
- `jack-devops-eks-admin-role`

## Contributing

This is a personal learning project, but suggestions and feedback are welcome.

## License

This project is for educational and demonstration purposes.

## Acknowledgments

Built as part of a DevOps learning journey and interview preparation process.
