# Consistency

## Definition
Consistency in distributed systems means that all nodes see the same data at the same time. When a write is made to one node, all subsequent reads from any node should return that value.

## Real-World Example
**Google Spanner**: Provides external consistency (strongest form) using TrueTime and the Paxos consensus algorithm. This is why Spanner can power Google's global advertising system where financial accuracy is critical.

## Consistency Models

### Strong Consistency
```
Write:  x = 5 ──► Node A (x=5)
                 Node B (x=5)  ──► Read: 5  (guaranteed)
                 Node C (x=5)
```

### Eventual Consistency
```
Write:  x = 5 ──► Node A (x=5)
                 Node B (x=3)  ──► Read: 3  (stale!)
                 Node C (x=3)
                 ... time passes ...
                 Node B (x=5)  ──► Read: 5
                 Node C (x=5)  ──► Read: 5
```

### Causal Consistency
```
Write 1: x = 1
Write 2: y = x + 1  (y depends on x)
         ──► All nodes see x=1 before y=2
```

### Read-My-Writes Consistency
```
User writes:    x = 5
User reads:     x = 5  (guaranteed to see own write)
Other users:    x = 3  (may see stale)
```

## Consistency Spectrum

```
Weaker ◄────────────────────────────────────────────────► Stronger
    │           │           │           │           │
    │           │           │           │           │
  Eventual    Causal    Read-My-    Monotonic   Strong
                        Writes       Read
    │                                          
    │                                          
    ▼                                          
Performance / Availability (higher)
                                          
                                          ▲
                                          │
                                        Consistency
                                        (higher)
```

## Tradeoffs

| Model | Consistency | Latency | Availability | Complexity |
|-------|-------------|---------|--------------|------------|
| Strong | ✅ High | ❌ High | ❌ Lower | ❌ High |
| Eventual | ❌ Low | ✅ Low | ✅ High | ✅ Low |
| Causal | ⚠️ Medium | ⚠️ Medium | ✅ High | ⚠️ Medium |
| Read-My-Writes | ⚠️ Medium | ✅ Low | ✅ High | ⚠️ Medium |

## Consistency in Practice

### Strong Consistency Systems
- **Google Spanner**: External consistency via TrueTime + Paxos
- **ZooKeeper**: Linearizable writes via Zab consensus
- **etcd**: Raft-based consensus for Kubernetes

### Eventual Consistency Systems
- **DynamoDB**: Configurable (EVENTUAL vs STRONG per request)
- **Cassandra**: Tunable consistency per query
- **DNS**: Eventually consistent by design

### Quorum-Based Consistency

```
N = total replicas
W = write quorum size
R = read quorum size

Strong consistency:  W + R > N
Example: N=3, W=2, R=2 ──► 2+2=4 > 3 ──► Strong

Eventual:            W + R ≤ N
Example: N=3, W=1, R=1 ──► 1+1=2 ≤ 3 ──► Eventual
```

## Diagram: Consistency Levels

```
Strong (W+R > N):
  Write ──► [Node1] [Node2] [Node3]
              │       │       │
              └───────┼───────┘
                      │    2 of 3 confirmed
                      ▼
                  Ack ──► Client

Eventual (W+R ≤ N):
  Write ──► [Node1]
              │     async
              │     ──────► [Node2]
              │     ──────► [Node3]
              ▼
          Ack ──► Client  (only 1 confirmed)
```

## Interview Questions
1. What consistency model does DNS use and why?
2. How do you achieve strong consistency in a distributed database?
3. What is read-after-write consistency and when is it important?
4. Design a social media feed with causal consistency
5. How does quorum size affect consistency and performance?
