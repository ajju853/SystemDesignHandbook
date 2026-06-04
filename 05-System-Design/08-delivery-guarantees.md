# Delivery Guarantees

## At-Most-Once
Message may be lost but never redelivered.

```
Producer ──► Broker (no ack) ──► Consumer (auto-ack)
                                        │
                                  Message processed ONCE
                                  or not at all

Use case: Logging, metrics (loss acceptable)
```

## At-Least-Once
Message never lost but may be redelivered.

```
Producer ──► Broker (ack) ──► Consumer (manual ack)
                                    │
                              Fail before ack ──► Redeliver

Use case: Notifications, email (duplicates tolerable)
```

## Exactly-Once
Message delivered exactly once — the gold standard.

```
Producer ──► Idempotent Producer ──► Broker ──► Transactional Consumer
    │                                  │
    └──── Transactional API ───────────┘
    
Kafka: enable.idempotence=true + transactions
SQS FIFO: Deduplication ID + Exactly-once processing

Use case: Payments, financial transactions
```

## Comparison

| Guarantee | Loss Risk | Duplicate Risk | Performance |
|-----------|-----------|----------------|-------------|
| At-most-once | ✅ Possible | ❌ No | Fastest |
| At-least-once | ❌ No | ✅ Possible | Fast |
| Exactly-once | ❌ No | ❌ No | Slowest |

```mermaid
flowchart LR
    subgraph At-Most-Once
        P1[Producer] -->|no ack| B1[Broker]
        B1 -->|auto-ack| C1[Consumer]
    end
    subgraph At-Least-Once
        P2[Producer] -->|ack| B2[Broker]
        B2 -->|manual ack| C2[Consumer]
    end
    subgraph Exactly-Once
        P3[Idempotent Producer] -->|transactional| B3[Broker]
        B3 -->|transactional| C3[Transactional Consumer]
    end
```
