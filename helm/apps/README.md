# ArgoCD Applications

This directory implements the App-of-Apps pattern for managing all applications in the cluster.

## Current Applications

- **root-app.yaml**: The root Application that manages all other applications

## App-of-Apps Pattern

```
root-app
└── (watches helm/argocd/apps/ directory)
    └── Any new Application manifests added here will be auto-deployed
```

## Deployment Sequence

1. Terraform creates EKS cluster
2. Terraform deploys ArgoCD
3. Terraform applies `root-app.yaml`
4. Root app watches this directory for new applications
5. Any new Application manifests are automatically deployed

## Adding New Applications

To add a new application:

1. Create a new Application manifest in this directory (e.g., `my-app.yaml`)
2. Commit and push to Git
3. The root-app will automatically detect and deploy it within 3 minutes
4. Or manually sync via ArgoCD UI

### Example Application Manifest

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
  labels:
    environment: prod
    managedBy: argocd
    project: eks-demo
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default

  source:
    repoURL: https://github.com/kyenzo/devops_demo.git
    targetRevision: HEAD
    path: path/to/my-app  # Path in this repo to your app manifests

  destination:
    server: https://kubernetes.default.svc
    namespace: my-app

  syncPolicy:
    automated:
      prune: true      # Remove resources when removed from Git
      selfHeal: true   # Auto-sync when cluster state drifts
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

## Sync Policies

All applications use automated sync with:
- **prune**: true - Remove resources deleted from Git
- **selfHeal**: true - Auto-correct drift from desired state
- **retry**: Exponential backoff on sync failures

## Best Practices

1. **Naming**: Use descriptive names (e.g., `nginx-ingress.yaml`, `prometheus.yaml`)
2. **Labels**: Include environment, managedBy, project labels
3. **Finalizers**: Always include `resources-finalizer.argocd.argoproj.io`
4. **Namespaces**: Use `CreateNamespace=true` sync option
5. **Projects**: Use appropriate ArgoCD Project for RBAC

## Verification

Check application status:

```bash
# List all applications
kubectl get applications -n argocd

# Describe specific application
kubectl describe application my-app -n argocd

# Watch sync status
kubectl get applications -n argocd -w
```

## Troubleshooting

### Application Not Syncing

```bash
# Check root-app status
kubectl get application root-app -n argocd

# Check application details
kubectl describe application my-app -n argocd

# Manual sync
kubectl patch application my-app -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'
```

### Application Stuck in Progressing

```bash
# Check events
kubectl get events -n argocd --sort-by='.lastTimestamp'

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller
```
