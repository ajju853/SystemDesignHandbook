# Jaeger

## Definition
Jaeger is an open-source distributed tracing system. It monitors and troubleshoots transactions in complex distributed systems.

```mermaid
sequenceDiagram
    participant C as Client
    participant A as Service A
    participant B as Service B
    participant D as Service C
    participant J as Jaeger
    C->>A: Request (trace_id=abc)
    activate A
    A->>A: Span: handle_request
    A->>B: RPC (trace_id=abc)
    activate B
    B->>B: Span: process
    B->>D: RPC (trace_id=abc)
    activate D
    D->>D: Span: db_query
    D-->>B: Response
    deactivate D
    B-->>A: Response
    deactivate B
    A-->>C: Response
    deactivate A
    A-->>J: Report traces
    B-->>J: Report traces
    D-->>J: Report traces
    J->>J: Store & index spans
    J->>UI: Visualize trace tree
```

## Architecture

```
Service ──► Jaeger Agent ──► Jaeger Collector ──► Storage
    │                           │                     │
    └── UDP/gRPC ──────────────►│                     │
                                │                     ▼
                           ┌────┴────┐          Cassandra/
                           │ Query   │          Elasticsearch
                           │ Service │          /Badger
                           └────┬────┘
                                │
                           ┌────▼────┐
                           │  UI     │
                           └─────────┘
```

## Key Features
- **Root-cause analysis** — Find failures across services
- **Latency optimization** — Identify bottlenecks
- **Service dependency analysis** — Map service topology
- **Performance optimization** — Find expensive operations
- **Sampling** — Head-based, tail-based, probabilistic

## Interview Questions
1. How does Jaeger's sampling work?
2. Compare Jaeger vs Zipkin for distributed tracing
3. How do you trace requests through a message queue?
4. What storage backends does Jaeger support?
5. Design a distributed tracing solution with Jaeger
