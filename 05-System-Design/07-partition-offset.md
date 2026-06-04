# Partition & Offset

## Partition
A partition is an ordered, immutable sequence of records within a topic.

```
Topic: "orders"
┌─────────────────────────────────────┐
│ Partition 0: [msg0] [msg1] [msg2]   │
├─────────────────────────────────────┤
│ Partition 1: [msg0] [msg1] [msg2]   │
├─────────────────────────────────────┤
│ Partition 2: [msg0] [msg1] [msg2]   │
└─────────────────────────────────────┘
```

**Partition key**: Producers can specify a key; same key → same partition (ordering per key).

## Offset
An offset is a unique sequential ID for each message within a partition.

```mermaid
graph LR
    subgraph Topic[Topic: orders]
        subgraph P0[Partition 0]
            direction LR
            M00[msg0] --> M01[msg1] --> M02[msg2]
        end
        subgraph P1[Partition 1]
            direction LR
            M10[msg0] --> M11[msg1] --> M12[msg2]
        end
        subgraph P2[Partition 2]
            direction LR
            M20[msg0] --> M21[msg1] --> M22[msg2]
        end
    end
    Producer -.-> P0
    Producer -.-> P1
    Producer -.-> P2
```

```
Partition 0 (offsets):
┌──────┬──────┬──────┬──────┬──────┐
│ 0    │ 1    │ 2    │ 3    │ 4    │
│ msgA │ msgB │ msgC │ msgD │ msgE │
└──────┴──────┴──────┴──────┴──────┘
         ▲                        ▲
      Consumer is here        Latest
      (offset=1)             (offset=5)
```

**Consumer tracks**: current offset per partition. On restart, starts from last committed offset.
