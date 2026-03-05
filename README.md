# DevOps Demo — AWS EKS Multi-Cluster Infrastructure

A production-style AWS infrastructure built with Terraform and managed entirely through GitOps (ArgoCD). Two Kubernetes clusters across two regions, connected via CloudFront CDN, with a full security and observability stack.

---

## What This Project Does

- Runs two EKS clusters: **prod** (ca-west-1, Canada) and **distant** (ap-southeast-1, Singapore)
- Serves traffic through **CloudFront CDN** with automatic failover between clusters
- Manages all applications declaratively via **ArgoCD** — push to Git, cluster updates itself
- Secures all inter-service communication with **Linkerd** mTLS service mesh
- Enforces policies cluster-wide with **Kyverno**
- Collects metrics with **Prometheus + Grafana**
- Runs **Kafka** event streaming via Strimzi operator
- Keeps secrets safe in **AWS Secrets Manager** via External Secrets Operator

---

## Architecture

```
                         ┌─────────────────────┐
                         │     CloudFront CDN   │
                         │  (active/passive      │
                         │    failover)          │
                         └────────┬────────┬────┘
                                  │        │
                    ┌─────────────┘        └─────────────┐
                    ▼                                     ▼
         ┌──────────────────┐                 ┌──────────────────┐
         │   prod cluster   │                 │  distant cluster │
         │   ca-west-1      │◄── VPC Peering ►│  ap-southeast-1  │
         │   (primary)      │                 │   (failover)     │
         └──────────────────┘                 └──────────────────┘
                    │
                    │  ArgoCD (runs on prod, manages both clusters)
                    │
         ┌──────────▼──────────────────────────────────┐
         │            Applications (prod cluster)       │
         │                                              │
         │  ingress-nginx  →  web-server                │
         │  Linkerd (mTLS for all services)             │
         │  cert-manager + ESO (certificate mgmt)       │
         │  Kyverno (policy enforcement)                │
         │  Kafka + Strimzi + Kafka UI                  │
         │  Prometheus + Grafana (monitoring)           │
         └──────────────────────────────────────────────┘
```

### Two-Cluster Setup

| Cluster | Region | Purpose |
|---------|--------|---------|
| prod | ca-west-1 (Calgary) | Primary — hosts all apps, runs ArgoCD |
| distant | ap-southeast-1 (Singapore) | Failover — runs web-server only |

CloudFront routes traffic to prod normally. If prod's origin health check fails, it automatically routes to distant. ArgoCD on prod manages both clusters via IRSA authentication.

---

## Infrastructure Components

### Terraform (`terraform/`)

Everything is provisioned with Terraform. Two environments share reusable modules.

```
terraform/
├── envs/
│   ├── prod/       — prod cluster, CloudFront, ArgoCD, ESO IRSA role
│   └── distant/    — distant cluster, VPC peering accepter
└── modules/
    ├── vpc/            — VPC, subnets, NAT gateway, VPC peering
    ├── eks/            — EKS cluster and managed node groups
    ├── iam-roles/      — EKS cluster/node IAM roles
    ├── security-groups/ — Security groups for EKS
    ├── argocd/         — ArgoCD Helm deployment + root app
    ├── cloudfront/     — CloudFront distribution with two origins
    └── s3-bucket/      — General-purpose S3 bucket
```

**Key Terraform resources in prod:**
- EKS cluster (v1.34, t3.large nodes, 2–4 instances)
- OIDC provider for IRSA
- ArgoCD IRSA role (manages distant cluster)
- ESO IRSA role (reads from AWS Secrets Manager)
- ingress-nginx Helm release (creates the internet-facing NLB)
- CloudFront distribution

### Kubernetes Applications (`helm/`)

All applications are managed by ArgoCD using the **ApplicationSet** pattern. Each environment (prod, distant) has its own ApplicationSet that lists which apps to deploy.

```
helm/
├── apps/
│   ├── root-app.yaml              — bootstraps ArgoCD App-of-Apps
│   ├── application-sets/
│   │   ├── prod.yaml              — all prod apps (helm + git)
│   │   └── distant.yaml           — distant apps
│   └── projects/
│       ├── prod.yaml              — ArgoCD project for prod
│       └── distant.yaml           — ArgoCD project for distant
├── argocd/                        — ArgoCD Helm values
├── cert-manager/                  — cert-manager Helm values
├── cert-manager-config/           — cert-manager resources (issuers, certs, ConfigMap)
├── eso/                           — External Secrets Operator values (IRSA annotation)
├── eso-config/                    — ClusterSecretStore + ExternalSecret for Linkerd
├── ingress-nginx/                 — ingress-nginx values
├── kafka/                         — Strimzi operator values + Kafka cluster manifest
├── kafka-ui/                      — Kafka UI values
├── kyverno/                       — Kyverno values + policies
├── linkerd/                       — Linkerd CRDs and control plane values
├── prometheus/                    — kube-prometheus-stack values
├── trust-manager/                 — trust-manager values (auto-distributes trust anchor cert)
└── web-server/                    — Web server Helm chart
```

---

## Deployment Order (Sync Waves)

ArgoCD deploys applications in a specific order using sync waves. Each wave completes before the next starts.

| Wave | Application | What it does |
|------|-------------|-------------|
| -4 | external-secrets | Installs ESO operator |
| -3 | cert-manager | Installs cert-manager |
| -3 | trust-manager | Installs trust-manager (watches cert-manager secrets, distributes ConfigMaps) |
| -3 | eso-config | Creates ClusterSecretStore + ExternalSecret (restores Linkerd trust anchor) |
| -2 | linkerd-crds | Installs Linkerd CRDs |
| -2 | cert-manager-config | Creates ClusterIssuer, certificates, Bundle (trust-manager distributes ConfigMap) |
| -2 | kyverno | Installs Kyverno |
| -1 | kyverno-policies | Deploys Kyverno policies |
| 0 | linkerd-control-plane | Deploys Linkerd service mesh |
| 0 | monitoring | Deploys Prometheus + Grafana |
| 0 | kafka-operator | Deploys Strimzi operator |
| 0 | kafka-ui | Deploys Kafka web UI |
| 0 | kafka-cluster | Creates Kafka cluster |
| 0 | web-server | Deploys the web server |

---

## Security Stack

### Linkerd (mTLS Service Mesh)

All services communicate over mutual TLS automatically. No application code changes needed — Linkerd injects a sidecar proxy into every pod.

Certificate chain:
- **Trust anchor** (10 year root CA) — generated by cert-manager, private key stored in AWS Secrets Manager via ESO so it survives daily cluster rebuilds
- **Identity issuer** (1 year intermediate CA) — signed by trust anchor, used by Linkerd to issue 24-hour mTLS certificates to each pod

The trust anchor public cert is committed to git in one place only:
- `helm/linkerd/control-plane-values.yaml` → `identity.trustAnchorsPEM` (read by Linkerd control plane)

The `linkerd-identity-trust-roots` ConfigMap that every proxy sidecar mounts is maintained automatically by **trust-manager** via the Bundle resource in `helm/cert-manager-config/trust-bundle.yaml`. It watches the cert-manager secret and keeps the ConfigMap in sync — no manual ConfigMap required.

### External Secrets Operator (ESO)

ESO pulls the Linkerd trust anchor key pair from AWS Secrets Manager and restores it into the `cert-manager` namespace on every cluster start. This ensures cert-manager reuses the same certificate instead of generating a new one, so the committed trust anchor cert never goes stale.

### Kyverno (Policy Engine)

Three policies enforced cluster-wide:
- No `latest` image tags
- All pods must have resource limits
- Required labels on all resources

---

## Getting Started

### Prerequisites

- AWS CLI configured
- Terraform >= 1.5
- kubectl
- An AWS account with permissions to create EKS, IAM, VPC, CloudFront resources

### 1. Deploy the prod cluster

```bash
cd terraform/envs/prod
terraform init
terraform apply
```

This creates the EKS cluster, installs ArgoCD, and deploys the root app. ArgoCD then takes over and deploys everything else automatically.

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --name jack-devops-eks-cluster --region ca-west-1
```

### 3. Bootstrap the Linkerd trust anchor (one-time)

After the first deployment, save the generated trust anchor to AWS Secrets Manager so it persists across rebuilds:

```bash
aws secretsmanager create-secret \
  --name linkerd/trust-anchor \
  --secret-string "{
    \"tls.crt\": \"$(kubectl get secret linkerd-trust-anchor -n cert-manager \
                      -o jsonpath='{.data.tls\.crt}' | base64 -d)\",
    \"tls.key\": \"$(kubectl get secret linkerd-trust-anchor -n cert-manager \
                      -o jsonpath='{.data.tls\.key}' | base64 -d)\"
  }"
```

Then extract the public cert and paste it into `helm/linkerd/control-plane-values.yaml` → `identity.trustAnchorsPEM`:

```bash
kubectl get secret linkerd-trust-anchor -n cert-manager \
  -o jsonpath='{.data.tls\.crt}' | base64 -d
```

trust-manager will handle the `linkerd-identity-trust-roots` ConfigMap automatically from there.

After this initial setup, the trust anchor is permanent — ESO restores it from AWS SM on every rebuild.

### 4. Deploy the distant cluster (optional)

```bash
cd terraform/envs/distant
terraform init
terraform apply
```

Then go back to prod and enable VPC peering by setting `distant_vpc_id` in `terraform/envs/prod/main.tf`.

### 5. Access ArgoCD

```bash
# Get the admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward to access the UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080
```

---

## Cluster Configuration

| Setting | Value |
|---------|-------|
| Region (prod) | ca-west-1 (Calgary) |
| Region (distant) | ap-southeast-1 (Singapore) |
| Kubernetes version | 1.34 |
| Node type | t3.large |
| Node count | 2 (min 1, max 4) |
| VPC CIDR (prod) | 10.0.0.0/16 |
| VPC CIDR (distant) | 10.1.0.0/16 |
| Availability zones | 3 per region |
| NAT gateways | 1 per cluster (cost saving) |

---

## Naming Convention

All AWS resources follow `jack-devops-{name}`:
- `jack-devops-eks-cluster`
- `jack-devops-eks-vpc`
- `jack-devops-argocd-irsa-role`
- `jack-devops-eso-irsa-role`

---

## Daily Cluster Rebuilds

This project is designed to be torn down and rebuilt daily to minimize AWS costs. The workflow:

1. `terraform destroy` — deletes everything
2. `terraform apply` — rebuilds the cluster
3. ArgoCD automatically redeploys all applications in the correct order
4. ESO restores the Linkerd trust anchor from AWS Secrets Manager — no manual cert updates needed

The only persistent state outside Kubernetes is:
- Terraform remote state (S3 + DynamoDB)
- Linkerd trust anchor key pair (AWS Secrets Manager)
