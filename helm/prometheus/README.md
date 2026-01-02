# Prometheus & Grafana Monitoring Stack

Comprehensive monitoring solution for the jack-devops EKS cluster using the kube-prometheus-stack, deployed via ArgoCD GitOps.

## Overview

This monitoring stack provides observability for your Kubernetes cluster with:

- **Prometheus**: Metrics collection and time-series database
- **Grafana**: Visualization and dashboarding
- **Prometheus Operator**: Kubernetes-native Prometheus management
- **Node Exporter**: Hardware and OS metrics from cluster nodes
- **Kube State Metrics**: Cluster-level Kubernetes object metrics
- **Pre-configured Dashboards**: Community dashboards for immediate insights

### What Gets Deployed

| Component | Replicas | Purpose |
|-----------|----------|---------|
| Prometheus | 1 | Metrics storage and querying |
| Grafana | 1 | Visualization and dashboards |
| Prometheus Operator | 1 | Manages Prometheus instances |
| Node Exporter | DaemonSet (1 per node) | Exports hardware/OS metrics |
| Kube State Metrics | 1 | Exports Kubernetes object metrics |
| AlertManager | 0 (disabled) | Alert routing (disabled for cost optimization) |

### Resource Requirements

**Total Resource Usage:**
- CPU requests: ~700m
- Memory requests: ~1.3Gi
- Storage: 4Gi (2Gi Prometheus + 2Gi Grafana)

**Node Compatibility:**
- Optimized for 2x t3.small nodes (2 CPU, 2Gi RAM each)
- Total cluster capacity: 4 CPU, 4Gi RAM
- Monitoring overhead: ~17.5% CPU, ~32.5% memory

### Cost Estimate

**Monthly Costs (AWS ca-west-1):**
- Storage (gp3): 4Gi @ $0.08/GB/month = $0.32/month
- Compute: Fits within existing nodes (no additional cost)
- Network: Uses existing NAT gateway (no additional cost)

**Total: ~$0.32/month**

## Quick Start

### Prerequisites

1. **EKS Cluster**: Running and accessible
2. **ArgoCD**: Deployed and configured (already done via Terraform)
3. **EBS CSI Driver**: Required for persistent volumes

Check if EBS CSI driver is installed:

```bash
kubectl get csidriver ebs.csi.aws.com
```

If not installed, deploy it:

```bash
# Via kubectl
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.25"
```

### Deployment

The monitoring stack is deployed automatically via ArgoCD when you commit the files to the master branch.

**Expected Deployment Time:** 5-7 minutes

**Steps:**

1. All files are already in `helm/prometheus/`
2. ArgoCD Application manifest is in `helm/apps/monitoring-app.yaml`
3. Commit and push to master branch
4. ArgoCD auto-syncs within 3 minutes

### Initial Validation

Check that all pods are running:

```bash
kubectl get pods -n monitoring
```

Expected output (should all be Running):
```
NAME                                                       READY   STATUS
kube-prometheus-stack-prometheus-0                         2/2     Running
kube-prometheus-stack-grafana-xxx                          3/3     Running
kube-prometheus-stack-operator-xxx                         1/1     Running
kube-prometheus-stack-kube-state-metrics-xxx               1/1     Running
kube-prometheus-stack-prometheus-node-exporter-xxx         1/1     Running
kube-prometheus-stack-prometheus-node-exporter-yyy         1/1     Running
```

Check PVCs are bound:

```bash
kubectl get pvc -n monitoring
```

## Accessing the UIs

### Prometheus

**Via Port-Forward:**

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

Then visit: http://localhost:9090

**Key Sections:**
- **Graph**: Run PromQL queries and visualize results
- **Targets**: View all scrape targets and their health
- **Alerts**: View active alerts (if AlertManager enabled)
- **Configuration**: View Prometheus configuration

### Grafana

**Get Admin Password:**

```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

**Via Port-Forward:**

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

Then visit: http://localhost:3000

**Login:**
- Username: `admin`
- Password: (from command above)

## Grafana Configuration Guide

### Pre-Configured Datasource

Prometheus is already configured as the default datasource:

**Verify:**
1. Go to Grafana UI (http://localhost:3000)
2. Configuration (gear icon) → Data Sources
3. You should see "Prometheus" with URL: `http://kube-prometheus-stack-prometheus:9090`

### Pre-Installed Community Dashboards

Three dashboards are automatically imported:

1. **Kubernetes Cluster Monitoring** (ID: 7249)
   - Overview of cluster health
   - Node CPU, memory, disk usage
   - Pod status and resource consumption
   - Network I/O

2. **Node Exporter Full** (ID: 1860)
   - Detailed node-level metrics
   - CPU, memory, disk, network per node
   - System load, temperature, uptime
   - Filesystem usage

3. **Prometheus Stats** (ID: 2)
   - Prometheus server performance
   - Scrape duration and samples
   - Query execution time
   - Storage usage

**Access:**
- Dashboards → Browse → Select any dashboard from the list

### Importing Additional Dashboards

**Method 1: Via Dashboard ID (Recommended)**

1. Go to Dashboards → Import
2. Enter a dashboard ID (find dashboards at https://grafana.com/grafana/dashboards/)
3. Select "Prometheus" as datasource
4. Click "Import"

**Popular Dashboard IDs:**
- **3119** - Kubernetes cluster monitoring (advanced)
- **315** - Kubernetes cluster monitoring (Prometheus)
- **6417** - Kubernetes cluster overview
- **12114** - Kubernetes API server
- **13332** - Kubernetes persistent volumes

**Method 2: Via JSON File**

1. Download dashboard JSON from Grafana.com
2. Go to Dashboards → Import
3. Upload JSON file
4. Select "Prometheus" as datasource
5. Click "Import"

### Creating Custom Dashboards

**Basic Steps:**

1. Go to Dashboards → New → New Dashboard
2. Click "Add visualization"
3. Select "Prometheus" datasource
4. Enter PromQL query (see examples below)
5. Customize visualization (graph, gauge, table, etc.)
6. Save dashboard

**Example: Pod CPU Usage Panel**

PromQL Query:
```promql
sum(rate(container_cpu_usage_seconds_total{namespace!=""}[5m])) by (namespace, pod)
```

Visualization: Time series graph

### Saving Dashboard Changes

**Important:** Changes to dashboards are saved to the Grafana PVC (persisted).

To export and version-control dashboards:

1. Go to Dashboard → Settings (gear icon) → JSON Model
2. Copy JSON
3. Save to `helm/prometheus/dashboards/my-dashboard.json`
4. Commit to Git for version control

## Prometheus Query Examples

Use these queries in Prometheus UI (http://localhost:9090) or Grafana:

### Node Metrics

**Node CPU Usage:**
```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Node Memory Usage:**
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

**Node Disk Usage:**
```promql
(node_filesystem_size_bytes{fstype!="tmpfs"} - node_filesystem_avail_bytes{fstype!="tmpfs"}) / node_filesystem_size_bytes{fstype!="tmpfs"} * 100
```

### Pod Metrics

**Pod CPU Usage:**
```promql
sum(rate(container_cpu_usage_seconds_total{namespace!="", pod!=""}[5m])) by (namespace, pod)
```

**Pod Memory Usage:**
```promql
sum(container_memory_working_set_bytes{namespace!="", pod!=""}) by (namespace, pod)
```

**Pod Restart Count:**
```promql
kube_pod_container_status_restarts_total
```

### Cluster Metrics

**Total Pod Count:**
```promql
count(kube_pod_info)
```

**Pod Count by Namespace:**
```promql
count(kube_pod_info) by (namespace)
```

**Pods Not Running:**
```promql
kube_pod_status_phase{phase!="Running"} == 1
```

### Network Metrics

**Network Received Bytes per Node:**
```promql
rate(node_network_receive_bytes_total[5m])
```

**Network Transmitted Bytes per Node:**
```promql
rate(node_network_transmit_bytes_total[5m])
```

### Kubernetes API Server

**API Server Request Latency (P95):**
```promql
histogram_quantile(0.95, sum(rate(apiserver_request_duration_seconds_bucket[5m])) by (le, verb))
```

**API Server Request Rate:**
```promql
sum(rate(apiserver_request_total[5m])) by (verb, code)
```

## Storage Management

### Monitoring PVC Usage

**Check PVC Status:**
```bash
kubectl get pvc -n monitoring
```

**Check Prometheus Disk Usage:**
```bash
kubectl exec -n monitoring prometheus-kube-prometheus-stack-prometheus-0 \
  -- df -h /prometheus
```

Expected usage: <1GB for 1-day retention with 30s scrape interval

**Check Grafana Disk Usage:**
```bash
kubectl exec -n monitoring $(kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}') \
  -- df -h /var/lib/grafana
```

### Expanding Volumes

If you need more storage (e.g., increase retention):

**1. Edit PVC:**
```bash
kubectl edit pvc prometheus-kube-prometheus-stack-prometheus-db-prometheus-kube-prometheus-stack-prometheus-0 -n monitoring
```

Change `storage: 2Gi` to desired size (e.g., `storage: 5Gi`)

**2. Resize will happen automatically** (gp3 supports volume expansion)

**3. Verify:**
```bash
kubectl get pvc -n monitoring
```

### Retention Policy

Current retention: **1 day**

To change retention, edit `helm/prometheus/values.yaml`:

```yaml
prometheus:
  prometheusSpec:
    retention: 7d  # Change to desired retention
    storage Spec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 8Gi  # Increase storage accordingly
```

Commit and push. ArgoCD will auto-sync.

**Storage Size Estimation:**
- 1 day retention @ 30s scrape: ~1GB
- 7 days retention @ 30s scrape: ~7-8GB
- Adjust accordingly based on scrape interval and cluster size

## Troubleshooting

### Pods Stuck in Pending

**Symptom:** Pods show `Pending` status

**Cause 1: PVC Not Binding**

Check PVC status:
```bash
kubectl describe pvc -n monitoring
```

If events show "waiting for a volume to be created":
- EBS CSI driver may not be installed
- StorageClass `gp3` may not exist

**Solution:**
```bash
# Check if gp3 StorageClass exists
kubectl get storageclass

# If not, create it or use default "gp2"
# Edit values.yaml and change storageClassName: gp2
```

**Cause 2: Insufficient Node Resources**

Check node capacity:
```bash
kubectl describe nodes
```

Look for "Allocated resources" section. If CPU or memory is over 100%, nodes are full.

**Solution:**
- Reduce resource requests in `values-prod.yaml`
- Or scale node group to 3 nodes

### Prometheus Pod OOMKilled

**Symptom:** Prometheus pod restarts frequently, `kubectl describe` shows OOMKilled

**Cause:** Memory limit too low for data retention

**Solution 1:** Increase memory limit in `values-prod.yaml`:
```yaml
prometheus:
  prometheusSpec:
    resources:
      limits:
        memory: 2Gi  # Increase from 1.5Gi
```

**Solution 2:** Reduce retention period:
```yaml
prometheus:
  prometheusSpec:
    retention: 12h  # Reduce from 1d
```

### Grafana Shows "No Data"

**Symptom:** Dashboards load but show "No Data" or "N/A"

**Cause 1:** Prometheus datasource not configured

**Solution:**
1. Go to Configuration → Data Sources
2. Verify Prometheus URL: `http://kube-prometheus-stack-prometheus:9090`
3. Click "Test" - should show "Data source is working"

**Cause 2:** Metrics not being scraped

**Solution:**
1. Port-forward to Prometheus: `kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090`
2. Visit http://localhost:9090/targets
3. Check if targets are "UP" - if down, check pod logs

### Metrics Not Appearing

**Symptom:** Some metrics are missing in Prometheus

**Cause:** Service monitors not detecting services

**Solution:**
Check service monitor selector:
```bash
kubectl get servicemonitors -n monitoring
```

Prometheus only scrapes services that match service monitor selectors.

### ArgoCD Application Not Syncing

**Symptom:** `kubectl get application monitoring -n argocd` shows `OutOfSync`

**Cause:** Helm chart dependency not downloaded

**Solution:**
ArgoCD will auto-download dependencies. Wait 3-5 minutes. If still failing:

1. Check ArgoCD logs:
```bash
kubectl logs -n argocd deployment/argocd-repo-server | grep monitoring
```

2. Manually sync:
```bash
kubectl patch application monitoring -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'
```

## Cost Optimization

### Current Configuration

- **Retention:** 1 day (minimal storage costs)
- **Scrape Interval:** 30s (balanced metrics vs storage)
- **AlertManager:** Disabled (saves ~$0.10/month)
- **Replicas:** All set to 1 (minimal compute)

### Further Optimizations

**1. Reduce Scrape Interval:**

Edit `values.yaml`:
```yaml
prometheus:
  prometheusSpec:
    scrapeInterval: 60s  # From 30s
```

**Savings:** ~50% storage reduction

**2. Use Ephemeral Storage (emptyDir):**

Edit `values.yaml`:
```yaml
prometheus:
  prometheusSpec:
    storageSpec: {}  # Remove PVC configuration
```

**Savings:** $0.16/month (Prometheus PVC eliminated)
**Caveat:** Metrics lost on pod restart

**3. Disable Grafana Persistence:**

Edit `values.yaml`:
```yaml
grafana:
  persistence:
    enabled: false
```

**Savings:** $0.16/month (Grafana PVC eliminated)
**Caveat:** Custom dashboards lost on pod restart

### Production Considerations

For production environments, consider:

1. **High Availability:** 3 replicas for Prometheus, Grafana, AlertManager
2. **Long-term Storage:** Thanos or Cortex for multi-year retention
3. **Dedicated Nodes:** m5.xlarge or larger for monitoring workloads
4. **Increased Retention:** 30-90 days for troubleshooting historical issues
5. **AlertManager:** Re-enable for critical alerting (Slack, PagerDuty, email)
6. **Ingress Controller:** Expose Grafana via HTTPS with authentication
7. **Remote Write:** Send metrics to external systems (Datadog, New Relic, etc.)

## Cleanup

### Delete via ArgoCD

ArgoCD will automatically delete all resources:

```bash
kubectl delete application monitoring -n argocd
```

This will:
1. Delete all pods
2. Delete services
3. Delete persistent volumes (based on PVC retain policy)
4. Delete namespace (after all resources are cleaned up)

### Manual Cleanup

If you need to manually clean up:

```bash
# Delete namespace (deletes all pods)
kubectl delete namespace monitoring

# Delete PVCs (if not auto-deleted)
kubectl delete pvc -n monitoring --all
```

**Note:** EBS volumes will be deleted when PVCs are deleted (default reclaim policy: Delete).

## Next Steps

1. **Import Additional Dashboards:** Browse https://grafana.com/grafana/dashboards/
2. **Create Custom Dashboards:** Build dashboards specific to your applications
3. **Enable AlertManager:** Configure alerting for critical conditions
4. **Add Application Metrics:** Instrument applications to export custom metrics
5. **Set Up Recording Rules:** Pre-compute expensive queries
6. **Configure Ingress:** Expose Grafana via ingress controller (NGINX)
7. **Implement Remote Write:** Send metrics to long-term storage (Thanos, Cortex)

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [kube-prometheus-stack Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)

## Support

For issues or questions:

1. Check ArgoCD application status: `kubectl get application monitoring -n argocd`
2. Check pod logs: `kubectl logs -n monitoring <pod-name>`
3. Review [COMMANDS.md](./COMMANDS.md) for troubleshooting commands
4. Consult the plan file: `/Users/evgenis/.claude/plans/dreamy-mapping-cookie.md`
