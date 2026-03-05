# Helm — Application Configuration

This directory contains all Kubernetes application configuration managed by ArgoCD. Everything here is declarative — ArgoCD watches this directory and applies changes to the cluster automatically when you push to `master`.

---

## How Applications Are Deployed

ArgoCD uses the **ApplicationSet** pattern. Instead of one Application manifest per app, there are two ApplicationSets per cluster that generate applications from a list:

- **prod-helm-apps** — external Helm charts (cert-manager, Linkerd, Prometheus, etc.)
- **prod-git-apps** — raw Kubernetes manifests from this repo (cert-manager-config, eso-config, etc.)

Both are defined in `helm/apps/application-sets/prod.yaml`.

Adding a new app is as simple as adding an entry to the list in that file.

---

## Directory Overview

```
helm/
├── apps/                        — ArgoCD configuration (ApplicationSets, Projects)
├── argocd/                      — ArgoCD Helm values (managed by Terraform)
├── cert-manager/                — cert-manager Helm values
├── cert-manager-config/         — cert-manager resources (issuers, certs, ConfigMap)
├── eso/                         — External Secrets Operator Helm values
├── eso-config/                  — ESO ClusterSecretStore and ExternalSecret
├── ingress-nginx/               — ingress-nginx values (deployed by Terraform directly)
├── kafka/                       — Strimzi operator values + Kafka cluster manifest
├── kafka-ui/                    — Kafka UI values
├── kyverno/                     — Kyverno values and policies
├── linkerd/                     — Linkerd CRDs and control plane values
├── prometheus/                  — kube-prometheus-stack values
└── web-server/                  — Web server Helm chart (templates + values)
```

---

## Sync Waves — Deployment Order

Applications deploy in order. A wave must complete successfully before the next wave starts. This ensures dependencies are ready before dependents.

```
Wave -4:  external-secrets         (ESO operator — needed before eso-config)
Wave -3:  cert-manager             (needed before cert-manager-config)
          eso-config               (restores Linkerd trust anchor from AWS SM)
Wave -2:  linkerd-crds             (CRDs before control plane)
          cert-manager-config      (issuers, certs, trust roots ConfigMap)
          kyverno                  (operator before policies)
Wave -1:  kyverno-policies         (policies after operator is ready)
Wave  0:  linkerd-control-plane    (needs certs and CRDs from earlier waves)
          monitoring               (Prometheus + Grafana)
          kafka-operator           (Strimzi operator)
          kafka-cluster            (Kafka cluster CRD)
          kafka-ui                 (web interface)
          web-server               (the application)
```

---

## Adding a New Application

### External Helm chart

Add an entry to the `elements` list in the `prod-helm-apps` generator in `helm/apps/application-sets/prod.yaml`:

```yaml
- name: my-app
  namespace: my-app
  chartRepo: https://charts.example.com
  chart: my-chart
  chartVersion: "1.2.3"
  valuesFile: helm/my-app/values.yaml
  syncWave: "0"
```

Then create `helm/my-app/values.yaml` with your chart overrides.

### Raw Kubernetes manifests from this repo

Add an entry to the `prod-git-apps` generator:

```yaml
- name: my-config
  namespace: my-namespace
  path: helm/my-config
  syncWave: "0"
```

Then create `helm/my-config/` with your manifest files.

---

## Certificate Management (Linkerd)

The `cert-manager-config/` directory manages the Linkerd certificate chain:

1. **`clusterissuer-selfsigned.yaml`** — bootstrap self-signed issuer (creates the root CA)
2. **`certificate-trust-anchor.yaml`** — root CA cert (10 years, stored in `cert-manager` namespace)
3. **`issuer-linkerd.yaml`** — ClusterIssuer that uses the trust anchor to sign certs
4. **`certificate-identity-issuer.yaml`** — intermediate CA cert (1 year, stored in `linkerd` namespace)
5. **`configmap-trust-roots.yaml`** — ConfigMap mounted by Linkerd proxies with the trust anchor public cert

The trust anchor private key is preserved across cluster rebuilds by ESO (see `eso-config/`).

---

## Linkerd Service Mesh

`helm/linkerd/` contains two things:
- `crds-values.yaml` — values for the `linkerd-crds` chart (empty, CRDs need no customization)
- `control-plane-values.yaml` — values for `linkerd-control-plane`, including the trust anchor public cert

To enable Linkerd mTLS on a namespace, annotate it:
```bash
kubectl annotate namespace my-app linkerd.io/inject=enabled
```

---

## Web Server

`helm/web-server/` is a full Helm chart (not just values) because the web server is deployed from this repo, not an external chart.

The chart includes:
- `templates/deployment.yaml` — deployment with configurable env vars
- `templates/service.yaml` — ClusterIP service
- `templates/ingress.yaml` — ingress rule for ingress-nginx

The `CLUSTER_NAME` env var is overridden per-cluster via ApplicationSet parameters, so the app can report which cluster is serving the request.
