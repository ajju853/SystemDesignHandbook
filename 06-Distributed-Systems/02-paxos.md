# Paxos

## Definition
Paxos is a family of consensus protocols for reaching agreement in a network of unreliable processors. It's the foundational consensus algorithm in distributed systems.

```mermaid
sequenceDiagram
    participant P as Proposer
    participant A1 as Acceptor 1
    participant A2 as Acceptor 2
    participant A3 as Acceptor 3
    Note over P,A3: Phase 1: Prepare
    P->>A1: Prepare(n)
    P->>A2: Prepare(n)
    P->>A3: Prepare(n)
    A1-->>P: Promise(n, v0)
    A2-->>P: Promise(n, v0)
    A3-->>P: Promise(n, v0)
    Note over P,A3: Phase 2: Accept
    P->>A1: Accept(n, v)
    P->>A2: Accept(n, v)
    P->>A3: Accept(n, v)
    A1-->>P: Accepted
    A2-->>P: Accepted
    A3-->>P: Accepted
    Note over P: Value chosen (majority)
```

## Basic Paxos (Simplified)

### Roles
- **Proposer**: Proposes values
- **Acceptor**: Votes on proposals
- **Learner**: Learns the decided value
- **Leader**: Special single proposer (Multi-Paxos)

### Phase 1: Prepare
```
Proposer          Acceptors
    │                 │
    ├── Prepare(n) ──►│ n = proposal number
    │◄── Promise(n, v)│ Acceptors promise not to
    │                 │ accept lower-numbered proposals
```

### Phase 2: Accept
```
Proposer          Acceptors
    │                 │
    ├── Accept(n, v)─►│ Propose value v
    │◄── Accepted ────│ Majority accepts
    │                 │ Value is chosen
```

## Multi-Paxos
- Elects a stable leader (Phase 1 once)
- Leader proposes all subsequent values
- Majority accept on each proposal
- Log replication for state machines

## Interview Questions
1. Explain the two phases of Basic Paxos
2. What does Paxos guarantee about safety?
3. Why is Paxos considered hard to understand and implement?
4. How does Multi-Paxos improve on Basic Paxos?
5. Where is Paxos used in production systems?
