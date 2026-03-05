# ArgoCD

ArgoCD is the GitOps engine for this project. It watches this GitHub repository and keeps the cluster in sync with whatever is in `master`.

---

## Installation

ArgoCD is installed automatically by Terraform when the cluster is created. You do not need to run Helm manually.

```bash
cd terraform/envs/prod
terraform apply
# ArgoCD is installed as part of this step
```

The Terraform ArgoCD module uses the values files in this directory:
- `values.yaml` — base configuration
- `values-prod.yaml` — production overrides (resource limits, etc.)

---

## Accessing the UI

```bash
# Get the admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080 (username: admin)
```

---

## How ArgoCD Is Configured

- Monitors the `master` branch only
- All applications use automated sync with `prune: true` and `selfHeal: true`
- Applications are defined via ApplicationSets (see `helm/apps/application-sets/`)
- ArgoCD manages both the prod and distant clusters from the prod cluster

---

## Verifying Everything Is Healthy

```bash
kubectl get applications -n argocd
```

All apps should show `Synced` and `Healthy`. If something is degraded, check the app details:

```bash
kubectl describe application <app-name> -n argocd
```
