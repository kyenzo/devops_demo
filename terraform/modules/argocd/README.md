# ArgoCD Terraform Module

This module automatically deploys ArgoCD to an EKS cluster using the Helm and kubectl Terraform providers.

## Features

- Installs ArgoCD using official Helm chart
- Uses values from `helm/argocd/bootstrap/` directory
- Optionally deploys root application (App-of-Apps pattern)
- Optionally creates platform project for RBAC

## Usage

```hcl
module "argocd" {
  source = "../../modules/argocd"

  cluster_endpoint = module.eks.cluster_endpoint
  repository_url   = "https://github.com/kyenzo/devops_demo.git"

  enable_root_app         = true
  enable_platform_project = true
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| helm | ~> 2.12 |
| kubectl | ~> 1.14 |

## Providers

| Name | Version |
|------|---------|
| helm | ~> 2.12 |
| kubectl | ~> 1.14 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_endpoint | EKS cluster endpoint | `string` | n/a | yes |
| namespace | Namespace to install ArgoCD | `string` | `"argocd"` | no |
| argocd_chart_version | ArgoCD Helm chart version | `string` | `"7.8.1"` | no |
| repository_url | Git repository URL for ArgoCD | `string` | `"https://github.com/kyenzo/devops_demo.git"` | no |
| target_revision | Git branch/tag | `string` | `"HEAD"` | no |
| enable_root_app | Deploy root application | `bool` | `true` | no |
| enable_platform_project | Deploy platform project | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| argocd_namespace | Namespace where ArgoCD is installed |
| argocd_release_name | Helm release name |
| argocd_version | ArgoCD chart version installed |
| argocd_status | Status of Helm release |

## Post-Deployment

After Terraform completes, get the ArgoCD admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

Access ArgoCD UI:

```bash
# Via port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Or via LoadBalancer
kubectl get svc argocd-server -n argocd \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Notes

- ArgoCD will be installed automatically when EKS cluster is created
- The root application enables GitOps workflow immediately
- All applications in `helm/argocd/apps/` will be deployed automatically
- Changes to Helm values require `terraform apply` to update
