# Vertical Scaling

## Definition
Vertical scaling (scaling up/down) means increasing the capacity of a single machine by adding more resources — CPU, RAM, storage, or network bandwidth.

## Real-World Example
**Database Servers**: Many production PostgreSQL deployments run on a single powerful machine with 64+ cores, 512GB+ RAM, and NVMe SSDs. Companies often start with vertical scaling before adding read replicas.

## How It Works

```
Before                          After
┌─────────────────┐            ┌─────────────────┐
│ 4 Cores / 16GB  │   ──►     │ 32 Cores / 128GB│
│ ┌─────────────┐ │            │ ┌─────────────┐ │
│ │ App + DB    │ │            │ │ App + DB    │ │
│ └─────────────┘ │            │ └─────────────┘ │
└─────────────────┘            └─────────────────┘
      ▲                                    ▲
      │                                    │
  8,000 users                         100,000 users
```

## Advantages
- **Simple** — No architectural changes needed
- **Low latency** — All resources on the same machine
- **No distributed complexity** — No network partitions, no consistency issues
- **Easy maintenance** — One server to manage
- **Good for databases** — Many databases don't scale horizontally well

## Disadvantages
- **Hard limit** — Physical machine has maximum capacity
- **Expensive at high end** — Top-tier hardware costs grow exponentially
- **Single point of failure** — One machine goes down, system goes down
- **Downtime for upgrades** — Typically requires restarting the machine
- **Competition for resources** — CPU, I/O, memory all contested

## Vertical vs Horizontal at a Glance

| Aspect | Vertical | Horizontal |
|--------|----------|------------|
| **Maximum scale** | Limited by hardware | Theoretically unlimited |
| **Cost at scale** | Exponential | Linear |
| **Failure domain** | Whole system | One of many |
| **Architecture change** | None | Significant |
| **Management overhead** | Low | High |
| **Upgrade strategy** | Replace | Add/remove nodes |
| **Best for** | Stateful services | Stateless services |

## When Vertical Scaling Makes Sense

| Scenario | Why Vertical Works |
|----------|-------------------|
| **Early-stage startups** | Quick, cheap, no architectural debt |
| **Legacy monoliths** | Can't easily refactor to distributed |
| **Database primaries** | Many DBs optimize for single-node perf |
| **Memory-intensive workloads** | In-memory caches, analytics |
| **Low-latency requirements** | Avoids network hops |

## The Vertical Scaling Ceiling

```
Cost
▲
│                 ●─── x (Physical limit)
│              ●
│           ●
│        ●
│     ●
│  ●
│●
└──────────────────────────► Resources
```

As you approach the hardware ceiling, cost per unit of performance increases dramatically.

## Diagram: Upgrade Path

```
Phase 1:  8 cores / 32GB  ──► 50K users
Phase 2: 16 cores / 64GB  ──► 100K users
Phase 3: 32 cores / 128GB ──► 200K users
Phase 4: 64 cores / 512GB ──► 400K users ──► HIT CEILING
                                 │
                                 ▼
                     Add read replicas (horizontal)
```

## Interview Questions
1. When would you choose vertical scaling over horizontal?
2. What are the practical limits of vertical scaling?
3. How does vertical scaling affect cost efficiency?
4. When should a startup switch from vertical to horizontal scaling?
5. Why do databases often benefit more from vertical scaling than application servers?
