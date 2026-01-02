# ArgoCD Bootstrap

This directory contains the Helm configuration for installing ArgoCD on the jack-devops EKS cluster.

## Installation

### Prerequisites
- EKS cluster running (jack-devops-eks-cluster)
- kubectl configured with cluster access
- Helm 3.x installed

### Deploy ArgoCD

1. Create the argocd namespace:
   ```bash
   kubectl create namespace argocd
   ```

2. Install ArgoCD using Helm:
   ```bash
   helm install argocd . \
     --namespace argocd \
     --values values.yaml \
     --values values-prod.yaml \
     --create-namespace
   ```

3. Wait for ArgoCD to be ready:
   ```bash
   kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
   ```

4. Get the initial admin password:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

5. Access ArgoCD UI:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

   Or get the LoadBalancer URL:
   ```bash
   kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```

## Configuration

- **values.yaml**: Default configuration for all environments
- **values-prod.yaml**: Production-specific overrides

## Security Notes

- Change the default admin password immediately after installation
- In production, enable HTTPS and proper certificate management
- Consider using AWS Secrets Manager or External Secrets for sensitive data
