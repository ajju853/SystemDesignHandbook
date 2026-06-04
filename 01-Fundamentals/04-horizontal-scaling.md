# Horizontal Scaling

## Definition
Horizontal scaling (scaling out/in) means adding more machines or nodes to a system's pool of resources. Instead of upgrading a single server, you add additional servers to distribute the load.

## Real-World Example
**Google Search**: Processes 8.5 billion searches per day across hundreds of thousands of commodity servers. When traffic increases, Google adds more servers to the cluster rather than upgrading existing ones.

## How It Works

```
      ┌──────────┐
      │  Load     │
      │  Balancer │
      └────┬─────┘
           │
     ┌─────┼─────┐
     │     │     │
     ▼     ▼     ▼
  ┌────┐ ┌────┐ ┌────┐  ┌────┐
  │Srv1│ │Srv2│ │Srv3│  │SrvN│  ← Add more servers
  └────┘ └────┘ └────┘  └────┘
     │     │     │        │
     └─────┼─────┼────────┘
           │     │
           ▼     ▼
        ┌──────────┐
        │ Database  │
        │ Cluster   │
        └──────────┘
```

## Advantages
- **Infinite scaling** — Limited only by budget, not hardware
- **Cost-effective** — Use commodity hardware instead of expensive enterprise servers
- **Fault tolerant** — No single point of failure
- **Zero-downtime upgrades** — Roll machines one at a time
- **Elastic** — Scale up and down based on demand

## Disadvantages
- **Complex architecture** — Load balancers, distributed state, service discovery
- **Operational overhead** — More machines = more to manage
- **Network dependency** — Machines must communicate, adding latency
- **Data consistency** — Harder to maintain across nodes
- **Debugging complexity** — Issues are harder to reproduce across many machines

## When to Use

| Scenario | Recommendation |
|----------|---------------|
| Stateless applications (web servers) | Always prefer horizontal scaling |
| Stateful systems (databases) | Use with sharding/replication |
| High-traffic APIs | Horizontal with auto-scaling |
| Batch processing | Distribute across worker pool |
| Microservices | Default approach |

## Challenges

### Stateless vs Stateful
- **Stateless**: Easy to scale horizontally (web servers, APIs)
- **Stateful**: Harder — need distributed caching, database sharding, session management

### Session Management Strategies
1. **Sticky sessions** — Load balancer routes same user to same server
2. **Redis sessions** — Store sessions in a centralized cache
3. **JWT tokens** — Encode session data in the token itself

### Database Considerations
- Read replicas for read scaling
- Sharding for write scaling
- Distributed SQL or NoSQL databases

## Diagram: Auto-Scaling Group

```
                ┌────────────┐
                │ CloudWatch │
                │ (Metrics)  │
                └─────┬──────┘
                      │
                      ▼
                ┌────────────┐
                │ Auto       │
                │ Scaling    │
                │ Group      │
                └─────┬──────┘
                      │
        ┌─────────────┼──────────────┐
        │             │              │
        ▼             ▼              ▼
   ┌──────────┐ ┌──────────┐  ┌──────────┐
   │ EC2 Inst │ │ EC2 Inst │  │ EC2 Inst │
   │ (Healthy)│ │ (Healthy)│  │ (New)    │
   └──────────┘ └──────────┘  └──────────┘
        │             │              │
        └─────────────┼──────────────┘
                      │
                      ▼
                ┌────────────┐
                │ Target     │
                │ Group      │
                │ (ALB/NLB)  │
                └────────────┘
```

## Interview Questions
1. Design a system that can auto-scale based on traffic
2. How do you handle database connections when horizontally scaling application servers?
3. What's the difference between horizontal scaling for stateless vs stateful services?
4. How does horizontal scaling affect caching strategies?
5. What are the limits of horizontal scaling in practice?
