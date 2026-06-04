# Consensus

## Definition
Consensus is a fundamental problem in distributed computing where multiple nodes must agree on a single value or state. It's the foundation for leader election, atomic broadcast, and replicated state machines.

## The Consensus Problem

```mermaid
sequenceDiagram
    participant A as Node A
    participant B as Node B
    participant C as Node C
    participant D as Node D
    participant E as Node E
    
    A->>A: Propose: value_1
    B->>B: Propose: value_2
    C->>C: Propose: value_3
    D->>D: Propose: value_2
    E->>E: Propose: value_1
    
    Note over A,E: Phase 1: Propose
    
    A->>B: Prepare(N)
    B-->>A: Promise(N, last_accepted)
    A->>C: Prepare(N)
    C-->>A: Promise(N, last_accepted)
    
    Note over A,E: Phase 2: Accept
    
    A->>B: Accept(N, value_2)
    A->>C: Accept(N, value_2)
    A->>D: Accept(N, value_2)
    A->>E: Accept(N, value_2)
    
    B-->>A: Accepted(N, value_2)
    C-->>A: Accepted(N, value_2)
    D-->>A: Accepted(N, value_2)
    
    Note over A,E: Consensus reached: value_2
```

## Properties of Consensus
- **Validity**: Decided value was proposed
- **Agreement**: No two nodes decide differently
- **Termination**: Every correct node eventually decides
- **Integrity**: No node decides twice

## FLP Impossibility
The FLP result proves that in an asynchronous system, consensus is impossible if even one node can crash. Practical systems work around this with:
- Timeouts
- Leader-based protocols
- Failure detectors
- Randomized algorithms

## Protocols

| Protocol | Fault Tolerance | Performance | Complexity |
|----------|----------------|-------------|------------|
| Paxos | Tolerates N/2 failures | Moderate | High |
| Raft | Tolerates N/2 failures | Good | Medium |
| Zab (ZooKeeper) | Tolerates N/2 failures | Good | Medium |
| PBFT | Byzantine (1/3 failures) | Lower | Very High |

## Interview Questions
1. What is the consensus problem in distributed systems?
2. Explain the FLP impossibility result
3. Why do we need consensus in a distributed database?
4. Compare Paxos and Raft consensus protocols
5. How does etcd use Raft for Kubernetes coordination?
