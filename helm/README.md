# Kubernetes GitOps Configuration

This directory contains ArgoCD configuration for managing applications on the jack-devops EKS cluster via GitOps.

## Structure

```
helm/
├── argocd/                      # ArgoCD installation configuration
│   ├── values.yaml             # Default ArgoCD settings
│   ├── values-prod.yaml        # Production overrides
│   ├── Chart.yaml              # Chart metadata (reference)
│   └── README.md               # Installation guide
├── apps/                        # Application manifests (managed by ArgoCD)
│   ├── root-app.yaml           # Root Application (App-of-Apps)
│   └── README.md
├── README.md                    # This file
├── AUTOMATION.md                # How Terraform automation works
└── QUICKSTART.md                # Quick verification guide
```

## Automated Deployment

ArgoCD is **automatically deployed by Terraform** when you create the EKS cluster:

```bash
cd terraform/envs/prod
terraform apply
```

This will:
1. Create EKS cluster
2. Install ArgoCD using Helm provider
3. Deploy root application for App-of-Apps pattern
4. Enable GitOps - ArgoCD watches this repository

See [AUTOMATION.md](AUTOMATION.md) for details.

## Quick Start

### 1. Access ArgoCD UI

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access: https://localhost:8080 (admin / password-from-above)
```

### 2. Verify Applications

```bash
kubectl get applications -n argocd
# Should show: root-app (Synced & Healthy)
```

## Directory Details

### argocd/
ArgoCD installation configuration used by Terraform.

**Active files:**
- `values.yaml` - Default ArgoCD configuration (read by Terraform)
- `values-prod.yaml` - Production overrides (read by Terraform)

**Reference files:**
- `Chart.yaml` - Shows chart version being used
- `README.md` - Manual installation steps (for reference)

### apps/
Application manifests managed by ArgoCD (App-of-Apps pattern).

**Files:**
- `root-app.yaml` - Root application that watches this directory
  - Deployed by Terraform initially
  - Manages all child applications from Git

**To add new applications:**
1. Create a new Application YAML in this directory
2. Commit and push to Git
3. Root app will automatically deploy it


## GitOps Workflow

```
Developer makes change → Commit to Git → Push to master branch
                                              ↓
                                    ArgoCD detects change
                                              ↓
                                   ArgoCD syncs to cluster
```

**Branch Monitoring**: ArgoCD is configured to monitor only the `master` branch for production deployments. Changes to other branches will not trigger automatic deployments.

### Making Changes

1. Edit any file in `helm/apps/`
2. Commit and push to the `master` branch on GitHub
3. ArgoCD auto-syncs within 3 minutes
4. Or manually sync in ArgoCD UI

## Adding Applications

Create a new Application manifest in `helm/apps/`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/kyenzo/devops_demo.git
    targetRevision: HEAD
    path: path/to/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

The root-app will automatically detect and deploy it.

## Configuration Changes

### Modify ArgoCD Settings

Edit `helm/argocd/bootstrap/values.yaml` or `values-prod.yaml`, then:

```bash
cd terraform/envs/prod
terraform apply
```

Terraform will update ArgoCD with new configuration.

## Naming Conventions

- **Prefix**: `jack-devops-`
- **Namespaces**: `{application-name}` (e.g., `argocd`)
- **Labels**: environment=prod, managedBy=helm/argocd, project=eks-demo

## Troubleshooting

### ArgoCD Not Syncing

```bash
# Check application status
kubectl get applications -n argocd
kubectl describe application root-app -n argocd

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-server
```

### Manually Sync Application

```bash
# Via kubectl
kubectl patch application root-app -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'

# Or via ArgoCD CLI
argocd app sync root-app
```

## Next Steps

1. **Add Applications**: Create new Application manifests in `argocd/apps/`
2. **Monitor**: Set up monitoring with Prometheus/Grafana
3. **Ingress**: Add ingress controller for external access
4. **CI/CD**: Integrate with GitHub Actions for automated deployments

## Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [App-of-Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [GitOps Principles](https://opengitops.dev/)
- [Automation Details](AUTOMATION.md)
- [Quick Start Guide](QUICKSTART.md)
