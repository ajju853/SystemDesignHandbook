# Producer & Consumer

## Producer
A producer sends messages to a queue/topic.

```
Producer ──send()──► Queue/Topic
   │                      │
   ack ◄──────────────────┘
```

**Key properties**:
- **acks**: 0 (fire-forget), 1 (leader), -1 (all replicas)
- **retries**: Automatic retry on failure
- **batch.size**: Group messages for efficiency
- **linger.ms**: Max wait time before sending batch

## Consumer
A consumer receives messages from a queue/topic.

```
Consumer ◄──poll()─── Queue/Topic
   │
   ack ──────────────► (commit offset)
```

**Key properties**:
- **auto.offset.reset**: earliest/latest/none
- **enable.auto.commit**: Auto or manual offset commit
- **max.poll.records**: Max per poll call

## Consumer Group

```
Topic: orders [P0] [P1] [P2] [P3]
                │    │    │    │
Consumer Group:  C1   C1   C2   C2
(orders-service) 

Each partition assigned to one consumer in group.
If C1 fails: partitions rebalanced.

```mermaid
graph LR
    subgraph Producers
        P1[Producer 1]
        P2[Producer 2]
    end
    subgraph Topic[Topic: orders]
        PT0[Partition 0]
        PT1[Partition 1]
        PT2[Partition 2]
        PT3[Partition 3]
    end
    subgraph ConsumerGroup[Consumer Group]
        C1[Consumer 1]
        C2[Consumer 2]
    end
    P1 --> PT0
    P1 --> PT1
    P2 --> PT2
    P2 --> PT3
    PT0 --> C1
    PT1 --> C1
    PT2 --> C2
    PT3 --> C2
```
