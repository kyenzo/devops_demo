# Kafka on EKS (Strimzi)

Apache Kafka deployment using Strimzi Operator - a CNCF project for running Kafka on Kubernetes.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Kafka Namespace                       │
│                                                          │
│  ┌──────────────────┐                                   │
│  │ Strimzi Operator │ (manages Kafka CRDs)              │
│  └────────┬─────────┘                                   │
│           │ creates/manages                             │
│           ▼                                             │
│  ┌──────────────────┐    ┌──────────────────┐          │
│  │  Kafka Broker    │◄───│    Kafka UI      │          │
│  │  + Zookeeper     │    │  (Web Interface) │          │
│  │  Port: 9092      │    │   Port: 80       │          │
│  └──────────────────┘    └──────────────────┘          │
│           │                       │                     │
│  kafka-kafka-bootstrap:9092   LoadBalancer:80          │
└─────────────────────────────────────────────────────────┘
```

## Components

| Component | Version | Purpose |
|-----------|---------|---------|
| Strimzi Operator | 0.45.0 | Manages Kafka clusters via CRDs |
| Kafka | 3.9.0 | Message broker (1 replica) |
| Zookeeper | - | Metadata management (1 replica) |
| Kafka UI (Provectus) | 0.7.6 | Web interface for management |

## ArgoCD Applications

| Application | Description |
|-------------|-------------|
| kafka-operator | Installs Strimzi Operator |
| kafka-cluster | Creates Kafka + Zookeeper cluster |
| kafka-ui | Web interface for Kafka |

## Quick Access

### Kafka UI (Web Interface)

Get the LoadBalancer URL:
```bash
kubectl get svc -n kafka kafka-ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo
```

Or port-forward locally:
```bash
kubectl port-forward -n kafka svc/kafka-ui 8080:80
# Access at http://localhost:8080
```

### Kafka Bootstrap Server

Internal address (for applications in the cluster):
```
kafka-kafka-bootstrap.kafka.svc.cluster.local:9092
# or simply from within kafka namespace:
kafka-kafka-bootstrap:9092
```

## Useful Commands

### Check Pod Status

```bash
kubectl get pods -n kafka
```

Expected pods:
- `strimzi-cluster-operator-*` - Strimzi operator
- `kafka-kafka-0` - Kafka broker
- `kafka-zookeeper-0` - Zookeeper
- `kafka-entity-operator-*` - Topic/User operator
- `kafka-ui-*` - Web UI

### View Kafka Logs

```bash
kubectl logs -n kafka kafka-kafka-0 -f
```

### Create a Topic

```bash
kubectl exec -it kafka-kafka-0 -n kafka -- \
  bin/kafka-topics.sh --create \
    --bootstrap-server localhost:9092 \
    --topic my-topic \
    --partitions 3 \
    --replication-factor 1
```

Or using Strimzi KafkaTopic CRD:
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

### List Topics

```bash
kubectl exec -it kafka-kafka-0 -n kafka -- \
  bin/kafka-topics.sh --list --bootstrap-server localhost:9092
```

### Describe a Topic

```bash
kubectl exec -it kafka-kafka-0 -n kafka -- \
  bin/kafka-topics.sh --describe \
    --bootstrap-server localhost:9092 \
    --topic my-topic
```

## Producer/Consumer Testing

### Start a Console Producer

```bash
kubectl exec -it kafka-kafka-0 -n kafka -- \
  bin/kafka-console-producer.sh \
    --broker-list localhost:9092 \
    --topic test-topic
# Type messages and press Enter to send
```

### Start a Console Consumer

```bash
kubectl exec -it kafka-kafka-0 -n kafka -- \
  bin/kafka-console-consumer.sh \
    --bootstrap-server localhost:9092 \
    --topic test-topic \
    --from-beginning
```

### Using a Temporary Kafka Client Pod

```bash
kubectl run kafka-client --rm -it \
  --image=quay.io/strimzi/kafka:0.45.0-kafka-3.9.0 \
  --namespace=kafka -- bash

# Inside the pod:
bin/kafka-console-producer.sh --broker-list kafka-kafka-bootstrap:9092 --topic test
bin/kafka-console-consumer.sh --bootstrap-server kafka-kafka-bootstrap:9092 --topic test --from-beginning
```

## Consumer Groups

### List Consumer Groups

```bash
kubectl exec -it kafka-kafka-0 -n kafka -- \
  bin/kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --list
```

### Describe Consumer Group

```bash
kubectl exec -it kafka-kafka-0 -n kafka -- \
  bin/kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --group my-consumer-group \
    --describe
```

## Strimzi Custom Resources

### View Kafka Cluster Status

```bash
kubectl get kafka -n kafka
kubectl describe kafka kafka -n kafka
```

### View Topics

```bash
kubectl get kafkatopic -n kafka
```

### View Users

```bash
kubectl get kafkauser -n kafka
```

## Troubleshooting

### Pod Not Starting

```bash
# Check events
kubectl describe pod -n kafka kafka-kafka-0

# Check operator logs
kubectl logs -n kafka deployment/strimzi-cluster-operator
```

### Kafka UI Can't Connect

1. Check Kafka cluster is ready:
   ```bash
   kubectl get kafka kafka -n kafka -o jsonpath='{.status.conditions}'
   ```

2. Verify bootstrap service exists:
   ```bash
   kubectl get svc -n kafka kafka-kafka-bootstrap
   ```

3. Test connection from Kafka UI pod:
   ```bash
   kubectl exec -it -n kafka deployment/kafka-ui -- \
     nc -zv kafka-kafka-bootstrap 9092
   ```

## Configuration

### Current Settings

| Setting | Value |
|---------|-------|
| Kafka Brokers | 1 |
| Zookeeper Nodes | 1 |
| Storage | Ephemeral (no persistence) |
| Replication Factor | 1 |
| Auto-create Topics | Enabled |
| Log Retention | 168 hours (7 days) |

### Scaling (Future)

To scale to 3 Kafka brokers, edit `helm/kafka/cluster/kafka-cluster.yaml`:
```yaml
spec:
  kafka:
    replicas: 3
  zookeeper:
    replicas: 3
```

## Connecting Applications

### Python (kafka-python)

```python
from kafka import KafkaProducer, KafkaConsumer

# Producer
producer = KafkaProducer(bootstrap_servers='kafka-kafka-bootstrap.kafka.svc.cluster.local:9092')
producer.send('my-topic', b'Hello Kafka!')

# Consumer
consumer = KafkaConsumer('my-topic', bootstrap_servers='kafka-kafka-bootstrap.kafka.svc.cluster.local:9092')
for message in consumer:
    print(message.value)
```

### Node.js (kafkajs)

```javascript
const { Kafka } = require('kafkajs');

const kafka = new Kafka({
  clientId: 'my-app',
  brokers: ['kafka-kafka-bootstrap.kafka.svc.cluster.local:9092']
});

// Producer
const producer = kafka.producer();
await producer.send({
  topic: 'my-topic',
  messages: [{ value: 'Hello Kafka!' }]
});

// Consumer
const consumer = kafka.consumer({ groupId: 'my-group' });
await consumer.subscribe({ topic: 'my-topic' });
await consumer.run({
  eachMessage: async ({ message }) => {
    console.log(message.value.toString());
  }
});
```

## Why Strimzi Instead of Bitnami?

Bitnami removed their free container images from Docker Hub on August 28, 2025. Strimzi is:
- A CNCF incubating project with active maintenance
- Uses official Apache Kafka images
- Provides Kubernetes-native management via CRDs
- Better suited for production Kafka deployments

## Sources

- [Strimzi Documentation](https://strimzi.io/documentation/)
- [Strimzi GitHub](https://github.com/strimzi/strimzi-kafka-operator)
- [Kafka UI Documentation](https://docs.kafka-ui.provectus.io/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
