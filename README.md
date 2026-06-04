# System Design Mastery

> From zero to staff engineer — a complete learning operating system for system design.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

## The Roadmap

```
Level 1 ──▶ Fundamentals ──────────▶ CAP, Scalability, Latency
Level 2 ──▶ Networking ────────────▶ TCP/IP, HTTP, DNS, CDN
Level 3 ──▶ Databases ─────────────▶ SQL, NoSQL, Sharding, Indexing
Level 4 ──▶ Caching ───────────────▶ Redis, CDN, Cache Patterns
Level 5 ──▶ Message Queues ────────▶ Kafka, RabbitMQ, SQS
Level 6 ──▶ Distributed Systems ───▶ Raft, Paxos, Consensus
Level 7 ──▶ Cloud Architecture ────▶ AWS, GCP, Azure, K8s
Level 8 ──▶ Real Architectures ────▶ Netflix, Uber, YouTube
Level 9 ──▶ Staff Engineer ────────▶ Tradeoffs, RFCs, Chaos
```

## What Makes This Different

| Feature | This Repo | Others |
|---------|-----------|--------|
| Structured learning path | ✅ | ❌ |
| Hands-on projects with code | ✅ | ❌ |
| Production incident analysis | ✅ | ❌ |
| Staff engineer content | ✅ | ❌ |
| Open-source architecture teardowns | ✅ | ❌ |
| Interview difficulty tiers | ✅ | ❌ |
| Interactive diagrams | ✅ | ❌ |
| Capacity calculators | ✅ | ❌ |

## Modules

| Module | Topics | Level |
|--------|--------|-------|
| [01 — Fundamentals](01-Fundamentals/README.md) | CAP, Scalability, Consistency, Latency | Beginner |
| [02 — Networking](02-Networking/README.md) | OSI, TCP, HTTP/2/3, DNS, CDN, gRPC | Beginner |
| [03 — Databases](03-Databases/README.md) | PostgreSQL, MongoDB, Cassandra, Sharding | Intermediate |
| [04 — Caching](04-Caching/README.md) | Redis, Memcached, Cache Patterns | Intermediate |
| [05 — Message Queues](05-Message-Queues/README.md) | Kafka, RabbitMQ, SQS, Delivery Guarantees | Intermediate |
| [06 — Distributed Systems](06-Distributed-Systems/README.md) | Raft, Paxos, ZooKeeper, Consensus | Advanced |
| [07 — Cloud Architecture](07-Cloud-Architecture/README.md) | AWS, GCP, Azure, K8s, Docker | Intermediate |
| [08 — Security](08-Security/README.md) | JWT, OAuth, RBAC, Encryption, WAF | Intermediate |
| [09 — Observability](09-Observability/README.md) | Prometheus, Grafana, ELK, Tracing | Intermediate |
| [10 — Open Source Architectures](10-Open-Source-Architectures/README.md) | Netflix, Uber, YouTube, Instagram | Advanced |
| [11 — Production Incidents](11-Production-Incidents/README.md) | Facebook 2021, AWS outages, postmortems | All Levels |
| [12 — Hands-On Projects](12-Hands-On-Projects/README.md) | URL Shortener, Chat, Uber Backend | All Levels |
| [13 — System Design Interviews](13-System-Design-Interviews/README.md) | Tracks from beginner to staff level | All Levels |
| [14 — Staff Engineer Level](14-Staff-Engineer-Level/README.md) | Tradeoffs, RFCs, Chaos Engineering | Staff+ |
| [15 — Interactive Tools](15-Tools/README.md) | Quiz Generator, Capacity Calc, Failure Sim | All Levels |

## How to Use This Repository

```
1. Start with Module 01 — no skipping
2. Build the hands-on projects as you go
3. Attempt interview questions after each module
4. Study real architectures after fundamentals are solid
5. Level up to staff engineer content last
```

## Prerequisites

- Basic programming knowledge (any language)
- Understanding of basic data structures (hash maps, trees, queues)
- Familiarity with basic operating system concepts

## Learning Path by Role

### 🟢 Backend Engineer
`01 → 02 → 03 → 04 → 05 → 06 → 07 → 09 → 10 → 15`

### 🟢 Full Stack Engineer  
`01 → 02 → 03 → 04 → 07 → 08 → 09 → 12 → 15`

### 🟢 DevOps / SRE
`01 → 02 → 03 → 05 → 06 → 07 → 09 → 11 → 14 → 15`

### 🟢 Engineering Manager
`01 → 02 → 03 → 07 → 10 → 11 → 13 → 14 → 15`

### 🟢 Staff+ Aspirant
`01 → 02 → 03 → 04 → 05 → 06 → 07 → 09 → 10 → 11 → 14 → 15`

## Interactive Tools

| Tool | Description |
|------|-------------|
| [Quiz Generator](15-Tools/quiz-generator.html) | 40+ questions across 9 modules with difficulty tiers |
| [Capacity Calculator](15-Tools/capacity-calculator.html) | Estimate traffic, storage, bandwidth, compute, costs |
| [Failure Simulator](15-Tools/failure-simulator.html) | Visual architecture with cascading failure simulation |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT
