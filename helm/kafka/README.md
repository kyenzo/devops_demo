# Kafka on EKS

Apache Kafka deployment using Bitnami Helm chart with KRaft mode (no Zookeeper).

## Architecture

```
┌─────────────────────────────────────────────┐
│              Kafka Namespace                 │
│                                              │
│  ┌────────────────┐    ┌────────────────┐   │
│  │  Kafka Broker  │◄───│   Kafka UI     │   │
│  │   (KRaft)      │    │  (Web Interface│   │
│  │   Port: 9092   │    │   Port: 80)    │   │
│  └────────────────┘    └────────────────┘   │
│         │                      │            │
│         │                      │            │
│  ClusterIP:9092      LoadBalancer:80        │
└─────────────────────────────────────────────┘
```

## Components

| Component | Version | Purpose |
|-----------|---------|---------|
| Kafka (Bitnami) | 32.4.3 | Message broker with KRaft mode |
| Kafka UI (Provectus) | 0.7.6 | Web interface for management |

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
kafka.kafka.svc.cluster.local:9092
# or simply:
kafka:9092
```

## Useful Commands

### Check Pod Status

```bash
kubectl get pods -n kafka
```

### View Kafka Logs

```bash
kubectl logs -n kafka -l app.kubernetes.io/name=kafka -f
```

### Create a Topic

```bash
kubectl exec -it -n kafka kafka-controller-0 -- \
  kafka-topics.sh --create \
    --bootstrap-server localhost:9092 \
    --topic my-topic \
    --partitions 3 \
    --replication-factor 1
```

### List Topics

```bash
kubectl exec -it -n kafka kafka-controller-0 -- \
  kafka-topics.sh --list --bootstrap-server localhost:9092
```

### Describe a Topic

```bash
kubectl exec -it -n kafka kafka-controller-0 -- \
  kafka-topics.sh --describe \
    --bootstrap-server localhost:9092 \
    --topic my-topic
```

### Delete a Topic

```bash
kubectl exec -it -n kafka kafka-controller-0 -- \
  kafka-topics.sh --delete \
    --bootstrap-server localhost:9092 \
    --topic my-topic
```

## Producer/Consumer Testing

### Start a Console Producer

```bash
kubectl exec -it -n kafka kafka-controller-0 -- \
  kafka-console-producer.sh \
    --broker-list localhost:9092 \
    --topic test-topic
# Type messages and press Enter to send
```

### Start a Console Consumer

```bash
kubectl exec -it -n kafka kafka-controller-0 -- \
  kafka-console-consumer.sh \
    --bootstrap-server localhost:9092 \
    --topic test-topic \
    --from-beginning
```

### Using a Temporary Kafka Client Pod

```bash
kubectl run kafka-client --rm -it \
  --image=bitnami/kafka:latest \
  --namespace=kafka -- bash

# Inside the pod:
kafka-console-producer.sh --broker-list kafka:9092 --topic test
kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic test --from-beginning
```

## Performance Testing

### Producer Performance Test

```bash
kubectl exec -it -n kafka kafka-controller-0 -- \
  kafka-producer-perf-test.sh \
    --topic perf-test \
    --num-records 10000 \
    --record-size 1024 \
    --throughput 1000 \
    --producer-props bootstrap.servers=localhost:9092
```

### Consumer Performance Test

```bash
kubectl exec -it -n kafka kafka-controller-0 -- \
  kafka-consumer-perf-test.sh \
    --bootstrap-server localhost:9092 \
    --topic perf-test \
    --messages 10000
```

## Consumer Groups

### List Consumer Groups

```bash
kubectl exec -it -n kafka kafka-controller-0 -- \
  kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --list
```

### Describe Consumer Group

```bash
kubectl exec -it -n kafka kafka-controller-0 -- \
  kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --group my-consumer-group \
    --describe
```

### Reset Consumer Group Offset

```bash
kubectl exec -it -n kafka kafka-controller-0 -- \
  kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --group my-consumer-group \
    --topic my-topic \
    --reset-offsets \
    --to-earliest \
    --execute
```

## Monitoring

### Check Broker Health

```bash
kubectl exec -it -n kafka kafka-controller-0 -- \
  kafka-broker-api-versions.sh --bootstrap-server localhost:9092
```

### View Metrics in Prometheus

If Prometheus ServiceMonitor is enabled, Kafka metrics are available at:
- Prometheus UI: Search for metrics starting with `kafka_`

Common metrics:
- `kafka_server_brokertopicmetrics_messagesin_total` - Messages received
- `kafka_server_brokertopicmetrics_bytesin_total` - Bytes received
- `kafka_server_replicamanager_underreplicatedpartitions` - Under-replicated partitions

## Troubleshooting

### Pod Not Starting

```bash
# Check events
kubectl describe pod -n kafka kafka-controller-0

# Check logs
kubectl logs -n kafka kafka-controller-0
```

### Kafka UI Can't Connect

1. Check Kafka pod is running:
   ```bash
   kubectl get pods -n kafka
   ```

2. Verify service endpoint:
   ```bash
   kubectl get endpoints -n kafka kafka
   ```

3. Test connection from Kafka UI pod:
   ```bash
   kubectl exec -it -n kafka deployment/kafka-ui -- \
     nc -zv kafka 9092
   ```

### Topic Not Created

Auto-creation is enabled. If topics aren't being created:
1. Check producer is sending to correct bootstrap server
2. Verify `autoCreateTopicsEnable: true` in values.yaml

## Configuration

### Current Settings

| Setting | Value |
|---------|-------|
| Brokers | 1 (combined controller+broker) |
| Persistence | Disabled (ephemeral) |
| Replication Factor | 1 |
| Heap Size | 512MB |
| Log Retention | 168 hours (7 days) |
| Auto-create Topics | Enabled |

### Scaling (Future)

To scale to 3 brokers, update values.yaml:
```yaml
controller:
  replicaCount: 3
```

## Connecting Applications

### Python (kafka-python)

```python
from kafka import KafkaProducer, KafkaConsumer

# Producer
producer = KafkaProducer(bootstrap_servers='kafka.kafka.svc.cluster.local:9092')
producer.send('my-topic', b'Hello Kafka!')

# Consumer
consumer = KafkaConsumer('my-topic', bootstrap_servers='kafka.kafka.svc.cluster.local:9092')
for message in consumer:
    print(message.value)
```

### Node.js (kafkajs)

```javascript
const { Kafka } = require('kafkajs');

const kafka = new Kafka({
  clientId: 'my-app',
  brokers: ['kafka.kafka.svc.cluster.local:9092']
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

## Sources

- [Bitnami Kafka Helm Chart](https://artifacthub.io/packages/helm/bitnami/kafka)
- [Kafka UI Documentation](https://docs.kafka-ui.provectus.io/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
