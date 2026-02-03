# Web Server for Datadog Monitoring

Simple Flask web server designed to demonstrate Datadog monitoring capabilities.

## Features

- **Multiple endpoints** for testing different scenarios
- **Logging** at various levels (INFO, WARNING, ERROR)
- **Custom metrics** endpoint
- **Datadog autodiscovery** annotations configured

## Endpoints

- `GET /` - Home endpoint with request counter
- `GET /health` - Health check endpoint
- `GET /slow` - Simulates slow response (1-3s delay)
- `GET /error` - Simulates 500 error
- `GET /metrics` - Custom metrics (request count, simulated CPU/memory)

## Local Development

### Run locally
```bash
pip install -r requirements.txt
python app.py
```

Access at `http://localhost:8086`

### Build Docker image
```bash
docker build -t web-server:1.0.0 .
docker run -p 8086:8086 web-server:1.0.0
```

## Deployment

The app is automatically deployed via ArgoCD:
- **ArgoCD App**: `helm/apps/web-server.yaml`
- **Helm Chart**: `helm/web-server/`
- **Namespace**: `web-server`
- **Replicas**: 2

## Datadog Integration

The deployment includes Datadog annotations for:
- **Log collection**: Python logs tagged with service name
- **Metrics collection**: Custom metrics from `/metrics` endpoint
- **APM**: Ready for distributed tracing (requires DD_TRACE_ENABLED)

## Testing Datadog Monitoring

1. Generate traffic:
```bash
kubectl port-forward -n web-server svc/web-server 8080:80

# Generate requests
for i in {1..100}; do curl http://localhost:8080/; done
for i in {1..20}; do curl http://localhost:8080/slow; done
for i in {1..10}; do curl http://localhost:8080/error; done
```

2. Check Datadog:
- **Logs**: Filter by `service:web-server`
- **Metrics**: Look for custom metrics from `/metrics`
- **APM**: View request traces (if APM enabled)
- **Infrastructure**: See pod metrics, resource usage
