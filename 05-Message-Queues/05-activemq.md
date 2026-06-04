# ActiveMQ

## Definition
Apache ActiveMQ is a popular open-source message broker written in Java that fully supports the Java Message Service (JMS) specification. It provides reliable, asynchronous messaging between distributed applications with support for both point-to-point and publish-subscribe models.

## Key Features
- **JMS 1.1 and 2.0 compliance** — Full JMS API support for Java applications
- **Multi-protocol** — AMQP, MQTT, STOMP, OpenWire, and WebSocket
- **Persistence** — KahaDB (fast file-based), JDBC (database-backed), LevelDB
- **Network of Brokers** — Multiple brokers connected in a topology
- **Advisory Messages** — Built-in monitoring via system topics
- **Scheduled Messages** — Delayed and periodic message delivery
- **Message Groups** — Group related messages for sequential processing

## Protocols Supported

| Protocol | Type | Use Case |
|----------|------|----------|
| **OpenWire** | Binary (native) | Java-to-Java, best performance |
| **AMQP 1.0** | Binary | Cross-platform, standard |
| **MQTT** | Lightweight | IoT, mobile devices |
| **STOMP** | Text-based | Scripting languages, WebSocket |
| **REST** | HTTP | Browser clients, simple integration |

## ActiveMQ vs RabbitMQ vs Kafka

| Feature | ActiveMQ | RabbitMQ | Kafka |
|---------|----------|----------|-------|
| **Primary protocol** | JMS, OpenWire | AMQP | Custom (binary) |
| **Language** | Java | Erlang | Java/Scala |
| **Performance** | ~10K msg/sec | ~50K msg/sec | ~1M msg/sec |
| **Message persistence** | KahaDB, JDBC | Mnesia, disk | Log-based |
| **Routing** | JMS selectors | Exchanges + bindings | Topic partitions |
| **Cluster** | Network of brokers | Erlang clustering | Kafka-native |
| **Best for** | Enterprise Java | General purpose | Event streaming |

## Deployment Topology

```
Single Broker:
  Producer → Broker (KahaDB) → Consumer

Network of Brokers (tree topology):
  Region-1: Broker-A ──network connector──► Broker-B (Hub)
  Region-2: Broker-C ──network connector──► Broker-B
  
  Producer → Broker-A → Broker-B → Broker-C → Consumer

Master-Slave for HA:
  Master: Active broker (handles all clients)
  Slave: Standby (replicates via shared store)
  On failure: Slave becomes active automatically
```

## Interview Questions

1. What is JMS and how does ActiveMQ implement it?
2. How does ActiveMQ's network of brokers work?
3. Compare ActiveMQ, RabbitMQ, and Kafka for enterprise use
4. What persistence options does ActiveMQ support and when to use each?
5. How do you monitor ActiveMQ in production?
6. How does ActiveMQ handle message redelivery and DLQ?
