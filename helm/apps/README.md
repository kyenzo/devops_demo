# ArgoCD Apps Configuration

This directory contains everything ArgoCD needs to know about what to deploy and where.

---

## Structure

```
helm/apps/
├── root-app.yaml              — bootstrapped by Terraform; watches this directory
├── application-sets/
│   ├── prod.yaml              — defines all prod cluster applications
│   └── distant.yaml           — defines all distant cluster applications
└── projects/
    ├── prod.yaml              — ArgoCD Project for prod (allowed repos, namespaces)
    └── distant.yaml           — ArgoCD Project for distant
```

---

## How It Works

Terraform deploys ArgoCD and applies `root-app.yaml`. The root app watches the `helm/apps/` directory. When ArgoCD finds the ApplicationSet files, it generates and deploys all the individual applications automatically.

```
Terraform applies root-app.yaml
    └── root-app watches helm/apps/
            └── finds application-sets/prod.yaml
                    └── generates: external-secrets, cert-manager, linkerd, ...
```

---

## ApplicationSets

Each environment has two ApplicationSets:

**prod-helm-apps** — for applications from external Helm chart repositories (cert-manager, Linkerd, Prometheus, etc.). Each app specifies a `chartRepo`, `chart`, `chartVersion`, and `valuesFile` pointing to our overrides in this repo.

**prod-git-apps** — for plain Kubernetes manifests stored in this repo (cert-manager-config, eso-config, kyverno-policies, web-server, kafka-cluster). Each app specifies a `path` in this repo.

---

## ArgoCD Projects

Projects control what each set of apps is allowed to do:

- **prod project** — allows all namespaces and all cluster resources, restricted to specific Helm chart repos
- **distant project** — same model, only allows the repos needed by the distant cluster apps

---

## Adding an Application to Prod

Open `helm/apps/application-sets/prod.yaml` and add an entry to the appropriate generator list.

For a Helm chart:
```yaml
- name: my-app
  namespace: my-app
  chartRepo: https://charts.example.com
  chart: my-chart
  chartVersion: "1.2.3"
  valuesFile: helm/my-app/values.yaml
  syncWave: "0"
```

For manifests from this repo:
```yaml
- name: my-config
  namespace: my-namespace
  path: helm/my-config
  syncWave: "0"
```

If the chart repo is new, also add it to `helm/apps/projects/prod.yaml` under `sourceRepos`.

Push to master and ArgoCD will pick it up within a few minutes.

---

## Sync Waves

The `syncWave` field controls deployment order. Lower numbers deploy first. ArgoCD waits for all apps in a wave to become healthy before starting the next wave.

See [helm/README.md](../README.md) for the full wave ordering.
