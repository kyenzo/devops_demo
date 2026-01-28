# Prometheus Metrics Guide

## Accessing Prometheus

Port-forward to Prometheus:
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

Open `http://localhost:9090`

## Debugging Prometheus

### Check Targets
1. Go to **Status > Targets** in Prometheus UI
2. Verify all targets are "UP"
3. If targets are down, check:
   - Pod is running: `kubectl get pods -n <namespace>`
   - Service exists: `kubectl get svc -n <namespace>`
   - ServiceMonitor exists: `kubectl get servicemonitor -n <namespace>`

### Check Configuration
1. Go to **Status > Configuration** to see loaded config
2. Go to **Status > Service Discovery** to see discovered targets

### Query Metrics
1. Use the **Graph** tab
2. Type metric name and press Execute
3. View as Table or Graph

## Exploring Available Metrics

### List All Metrics
In Prometheus UI, click the metrics dropdown in the query box to see all available metrics.

### Common Metric Patterns
- `up{job="<service>"}` - Service health (1=up, 0=down)
- `<metric>_total` - Counters (always increasing)
- `<metric>_bucket` - Histogram buckets
- `<metric>_count` - Count of observations
- `<metric>_sum` - Sum of observations

### Explore by Prefix
- `node_*` - Node Exporter metrics (CPU, memory, disk)
- `container_*` - Container metrics
- `kube_*` - Kubernetes state metrics
- `prometheus_*` - Prometheus internal metrics

## Top Default Metrics for Grafana

### Cluster Health
```promql
# Node availability
up{job="node-exporter"}

# Cluster CPU usage
sum(rate(container_cpu_usage_seconds_total[5m]))

# Cluster memory usage
sum(container_memory_working_set_bytes) / sum(node_memory_MemTotal_bytes) * 100
```

### Node Metrics
```promql
# CPU usage per node
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage per node
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100

# Disk usage per node
node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100

# Network traffic
rate(node_network_receive_bytes_total[5m])
rate(node_network_transmit_bytes_total[5m])
```

### Pod Metrics
```promql
# Pod CPU usage
sum(rate(container_cpu_usage_seconds_total{pod="<pod-name>"}[5m])) by (pod)

# Pod memory usage
sum(container_memory_working_set_bytes{pod="<pod-name>"}) by (pod)

# Pod restart count
kube_pod_container_status_restarts_total

# Pods per namespace
count(kube_pod_info) by (namespace)
```

### Kafka Metrics (Strimzi)
```promql
# Kafka broker status
kafka_server_replicamanager_leadercount

# Messages per topic
kafka_server_brokertopicmetrics_messagesinpersec_total

# Bytes in/out
rate(kafka_server_brokertopicmetrics_bytesinpersec_total[5m])
rate(kafka_server_brokertopicmetrics_bytesoutpersec_total[5m])

# Under-replicated partitions
kafka_server_replicamanager_underreplicatedpartitions
```

### Application Performance
```promql
# Request rate
rate(http_requests_total[5m])

# Request duration (95th percentile)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Error rate
rate(http_requests_total{status=~"5.."}[5m])
```

### Kubernetes Resources
```promql
# Deployments not ready
kube_deployment_status_replicas_unavailable > 0

# Pods pending
kube_pod_status_phase{phase="Pending"} > 0

# PVC usage
kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes * 100
```

## Creating Custom Dashboards in Grafana

1. Open Grafana UI
2. Click **+** > **Dashboard**
3. Add Panel
4. Select **Prometheus** as data source
5. Enter PromQL query from above
6. Customize visualization (Graph, Gauge, Table, etc.)
7. Save dashboard

## Useful PromQL Functions

- `rate(metric[5m])` - Per-second rate over 5 minutes
- `increase(metric[5m])` - Total increase over 5 minutes
- `avg_over_time(metric[5m])` - Average over 5 minutes
- `max_over_time(metric[5m])` - Maximum over 5 minutes
- `sum(metric) by (label)` - Sum grouped by label
- `topk(5, metric)` - Top 5 values
- `histogram_quantile(0.95, metric)` - 95th percentile
