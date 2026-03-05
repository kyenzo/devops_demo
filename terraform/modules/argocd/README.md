# Terraform Module — ArgoCD

Installs ArgoCD on an EKS cluster and deploys the root application that bootstraps GitOps.

---

## What It Does

1. Installs ArgoCD via Helm using the values files from `helm/argocd/`
2. Deploys the root Application (`helm/apps/root-app.yaml`) that watches the repo
3. ArgoCD takes over from there — it picks up the ApplicationSets and deploys everything

---

## Usage

```hcl
module "argocd" {
  source = "../../modules/argocd"

  cluster_endpoint = module.eks.cluster_endpoint
  repository_url   = "https://github.com/kyenzo/devops_demo.git"
  target_revision  = "master"
  enable_root_app  = true
  irsa_role_arn    = local.argocd_irsa_role_arn

  depends_on = [module.eks, aws_iam_role.argocd_irsa]
}
```

---

## Inputs

| Name | Description | Required |
|------|-------------|----------|
| `cluster_endpoint` | EKS cluster API endpoint | yes |
| `repository_url` | GitHub repo URL for ArgoCD to watch | yes |
| `target_revision` | Branch to monitor | yes |
| `enable_root_app` | Whether to deploy the root app | yes |
| `irsa_role_arn` | IAM role ARN for ArgoCD IRSA (multi-cluster access) | yes |

---

## Outputs

| Name | Description |
|------|-------------|
| `argocd_namespace` | Namespace where ArgoCD is installed |
| `argocd_release_name` | Helm release name |

---

## After Deployment

Get the ArgoCD admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

ArgoCD UI (port forward):

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
