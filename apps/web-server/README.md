# Web Server

A simple Python/Flask web server that runs on both the prod and distant EKS clusters. Traffic reaches it through CloudFront CDN → ingress-nginx → this service.

---

## Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /` | Returns a hello message including which cluster is serving |
| `GET /health` | Health check — returns 200 OK |
| `GET /slow` | Simulates a slow response (1–3 second delay) |
| `GET /error` | Returns a 500 error |
| `GET /metrics` | Request count and simulated resource metrics |

The `/` endpoint includes the `CLUSTER_NAME` env var in the response, so you can see whether CloudFront routed you to `prod` or `distant`.

---

## Local Development

```bash
pip install -r requirements.txt
python app.py
# Access at http://localhost:8086
```

Or with Docker:

```bash
docker build -t web-server:latest .
docker run -p 8086:8086 web-server:latest
```

---

## Kubernetes Deployment

The app is deployed via ArgoCD using the Helm chart at `helm/web-server/`. It runs in the `web-server` namespace on both clusters.

The `CLUSTER_NAME` environment variable is set per-cluster:
- prod cluster: `CLUSTER_NAME=prod`
- distant cluster: `CLUSTER_NAME=distant`

This override is applied by the ApplicationSet in `helm/apps/application-sets/distant.yaml` using a Helm parameter override.

---

## Traffic Flow

```
User → CloudFront → ingress-nginx (NLB) → web-server service → pod
```

CloudFront has two origins: prod NLB and distant NLB. It sends traffic to prod by default, and fails over to distant if prod's health check fails.

---

## Testing

```bash
# Port forward directly to the service
kubectl port-forward -n web-server svc/web-server 8080:80

curl http://localhost:8080/
curl http://localhost:8080/health
curl http://localhost:8080/slow
curl http://localhost:8080/error
```
