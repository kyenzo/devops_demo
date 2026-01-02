# Prometheus & Grafana Terminal Commands Reference

Quick reference guide for common commands to interact with the monitoring stack.

## Port Forwarding

### Prometheus UI

Access Prometheus web interface at http://localhost:9090

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

### Grafana UI

Access Grafana web interface at http://localhost:3000

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

### AlertManager (if enabled)

Access AlertManager web interface at http://localhost:9093

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
```

## Initial Setup

### Get Grafana Admin Password

```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

### Check All Monitoring Pods

```bash
kubectl get pods -n monitoring
```

Expected output:
- `kube-prometheus-stack-prometheus-0` - Running
- `kube-prometheus-stack-grafana-*` - Running
- `kube-prometheus-stack-operator-*` - Running
- `kube-prometheus-stack-kube-state-metrics-*` - Running
- `kube-prometheus-stack-prometheus-node-exporter-*` - Running (one per node)

### Check Persistent Volume Claims

```bash
kubectl get pvc -n monitoring
```

Expected PVCs:
- `prometheus-kube-prometheus-stack-prometheus-db-prometheus-kube-prometheus-stack-prometheus-0` - 2Gi (Bound)
- `kube-prometheus-stack-grafana` - 2Gi (Bound)

### Check ArgoCD Application Status

```bash
kubectl get application monitoring -n argocd
```

Should show: `HEALTH: Healthy` and `SYNC STATUS: Synced`

## Prometheus Operations

### View Prometheus Targets

Port forward and visit http://localhost:9090/targets

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

### Check Prometheus Configuration

```bash
kubectl exec -n monitoring prometheus-kube-prometheus-stack-prometheus-0 \
  -- cat /etc/prometheus/config_out/prometheus.env.yaml
```

### Check Prometheus Metrics Storage Size

```bash
kubectl exec -n monitoring prometheus-kube-prometheus-stack-prometheus-0 \
  -- df -h /prometheus
```

### View Prometheus Logs

```bash
kubectl logs -n monitoring prometheus-kube-prometheus-stack-prometheus-0 -f
```

## Grafana Operations

### View Grafana Logs

```bash
kubectl logs -n monitoring deployment/kube-prometheus-stack-grafana -f
```

### List All Grafana Dashboards via API

```bash
# Start port-forward in background
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &

# Get password
GRAFANA_PASSWORD=$(kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode)

# List dashboards
curl -u admin:$GRAFANA_PASSWORD http://localhost:3000/api/search
```

### Export Grafana Dashboard as JSON

```bash
# Get dashboard UID from Grafana UI or API

kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &

GRAFANA_PASSWORD=$(kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode)

DASHBOARD_UID="your-dashboard-uid"

curl -u admin:$GRAFANA_PASSWORD \
  http://localhost:3000/api/dashboards/uid/$DASHBOARD_UID \
  | jq '.dashboard' > dashboard-backup.json
```

## Monitoring Resource Usage

### Check Pod Resource Usage

```bash
kubectl top pods -n monitoring
```

### Check Node Resource Usage

```bash
kubectl top nodes
```

### Describe Monitoring Pods

```bash
kubectl describe pods -n monitoring
```

## Troubleshooting

### Check PVC Status

```bash
kubectl get pvc -n monitoring
kubectl describe pvc -n monitoring
```

### Check Events in Monitoring Namespace

```bash
kubectl get events -n monitoring --sort-by='.lastTimestamp'
```

### Check StorageClass

```bash
kubectl get storageclass gp3
```

If gp3 doesn't exist:

```bash
kubectl get storageclass
```

### Restart Grafana Pod

```bash
kubectl rollout restart deployment/kube-prometheus-stack-grafana -n monitoring
```

### Restart Prometheus

```bash
# Scale down
kubectl scale statefulset prometheus-kube-prometheus-stack-prometheus -n monitoring --replicas=0

# Wait a few seconds

# Scale up
kubectl scale statefulset prometheus-kube-prometheus-stack-prometheus -n monitoring --replicas=1
```

## ArgoCD Operations

### Check Application Sync Status

```bash
kubectl get application monitoring -n argocd -o yaml
```

### Force Sync Monitoring Application

```bash
kubectl patch application monitoring -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'
```

### View ArgoCD Logs for Monitoring App

```bash
kubectl logs -n argocd deployment/argocd-server | grep monitoring
```

## Cleanup Commands

### Delete Monitoring Application

ArgoCD will automatically clean up all resources:

```bash
kubectl delete application monitoring -n argocd
```

### Manual Cleanup (if needed)

```bash
# Delete namespace (will delete all pods)
kubectl delete namespace monitoring

# Delete PVCs (if they weren't auto-deleted)
kubectl delete pvc -n monitoring --all
```

## Useful PromQL Queries

Copy these queries into Prometheus UI (http://localhost:9090):

### Node CPU Usage

```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### Pod Memory Usage by Namespace

```promql
sum(container_memory_working_set_bytes{namespace!=""}) by (namespace, pod)
```

### Container Restart Count

```promql
kube_pod_container_status_restarts_total
```

### API Server Request Latency

```promql
apiserver_request_duration_seconds_bucket
```

### Disk Usage by Node

```promql
(node_filesystem_size_bytes{fstype!="tmpfs"} - node_filesystem_avail_bytes{fstype!="tmpfs"}) / node_filesystem_size_bytes{fstype!="tmpfs"} * 100
```

### Pod Count by Namespace

```promql
count(kube_pod_info) by (namespace)
```

### Network Received Bytes per Node

```promql
rate(node_network_receive_bytes_total[5m])
```

### Network Transmitted Bytes per Node

```promql
rate(node_network_transmit_bytes_total[5m])
```

## Quick Access Script

Save this as `monitoring-access.sh`:

```bash
#!/bin/bash

# Get Grafana password
GRAFANA_PASSWORD=$(kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode)

echo "========================================="
echo "Monitoring Stack Access"
echo "========================================="
echo ""
echo "Grafana:"
echo "  URL: http://localhost:3000"
echo "  Username: admin"
echo "  Password: $GRAFANA_PASSWORD"
echo ""
echo "Prometheus:"
echo "  URL: http://localhost:9090"
echo ""
echo "Starting port forwards..."
echo ""

# Start port forwards
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090 &

echo "Port forwards started. Press Ctrl+C to stop."
wait
```

Make executable:

```bash
chmod +x monitoring-access.sh
./monitoring-access.sh
```
