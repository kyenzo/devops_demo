# Kafka

Apache Kafka running on Kubernetes via the Strimzi operator. Deployed in KRaft mode — no Zookeeper required.

---

## Components

| Component | Version | Purpose |
|-----------|---------|---------|
| Strimzi Operator | 0.49.1 | Manages Kafka clusters via Kubernetes CRDs |
| Kafka | 4.0.0 | Message broker (KRaft mode, 1 node) |
| Kafka UI | 0.7.6 | Web interface for managing topics and messages |

---

## Architecture

```
kafka namespace
├── strimzi-cluster-operator    — watches Kafka CRDs and manages the cluster
├── kafka-controller-0          — Kafka broker + KRaft controller combined
├── kafka-entity-operator       — manages KafkaTopic and KafkaUser CRDs
└── kafka-ui                    — Provectus web UI
```

---

## Accessing Kafka UI

```bash
kubectl get svc -n kafka kafka-ui \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo
```

Or port-forward locally:

```bash
kubectl port-forward -n kafka svc/kafka-ui 8080:80
# Open http://localhost:8080
```

---

## Connecting to Kafka

From within the cluster:

```
kafka-kafka-bootstrap.kafka.svc.cluster.local:9092
```

From within the `kafka` namespace:

```
kafka-kafka-bootstrap:9092
```

---

## Useful Commands

### Check cluster status

```bash
kubectl get pods -n kafka
kubectl get kafka -n kafka
```

### Create a topic via CLI

```bash
kubectl exec -it kafka-controller-0 -n kafka -- \
  bin/kafka-topics.sh --create \
    --bootstrap-server localhost:9092 \
    --topic my-topic \
    --partitions 3 \
    --replication-factor 1
```

### Create a topic via CRD (recommended)

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: my-topic
  namespace: kafka
  labels:
    strimzi.io/cluster: kafka
spec:
  partitions: 3
  replicas: 1
```

### Produce and consume messages

```bash
# Producer
kubectl exec -it kafka-controller-0 -n kafka -- \
  bin/kafka-console-producer.sh \
    --broker-list localhost:9092 \
    --topic my-topic

# Consumer
kubectl exec -it kafka-controller-0 -n kafka -- \
  bin/kafka-console-consumer.sh \
    --bootstrap-server localhost:9092 \
    --topic my-topic \
    --from-beginning
```

### Using a temporary client pod

```bash
kubectl run kafka-client --rm -it \
  --image=quay.io/strimzi/kafka:0.49.1-kafka-4.0.0 \
  --namespace=kafka -- bash
```

---

## Connecting from Your Application

### Python

```python
from kafka import KafkaProducer, KafkaConsumer

producer = KafkaProducer(
    bootstrap_servers='kafka-kafka-bootstrap.kafka.svc.cluster.local:9092'
)
producer.send('my-topic', b'hello')

consumer = KafkaConsumer(
    'my-topic',
    bootstrap_servers='kafka-kafka-bootstrap.kafka.svc.cluster.local:9092'
)
for message in consumer:
    print(message.value)
```

### Node.js

```javascript
const { Kafka } = require('kafkajs');
const kafka = new Kafka({
  brokers: ['kafka-kafka-bootstrap.kafka.svc.cluster.local:9092']
});
```

---

## Current Configuration

| Setting | Value |
|---------|-------|
| Mode | KRaft (no Zookeeper) |
| Brokers | 1 (controller + broker combined) |
| Storage | Ephemeral (no EBS — data is lost on pod restart) |
| Replication factor | 1 |
| Log retention | 7 days |
| Listeners | Plain (9092), TLS (9093) |

---

## Troubleshooting

### Operator logs

```bash
kubectl logs -n kafka deployment/strimzi-cluster-operator
```

### Kafka broker logs

```bash
kubectl logs -n kafka kafka-controller-0 -f
```

### Kafka UI can't connect

```bash
# Check the bootstrap service exists
kubectl get svc -n kafka kafka-kafka-bootstrap

# Test connectivity from Kafka UI pod
kubectl exec -it -n kafka deployment/kafka-ui -- \
  nc -zv kafka-kafka-bootstrap 9092
```
