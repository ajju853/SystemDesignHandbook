# Uber Architecture

## Overview
Uber's architecture evolved from a monolith to a domain-oriented microservices architecture at massive scale.

## Architecture

```
Client ──► API Gateway
              │
         ┌────┴────┐
         │ Dispatch │───► Geospatial Index
         │ Service  │───► Pricing Engine
         └────┬────┘───► Marketplace
              │
         ┌────┴────┐
         │ Domain  │ (2200+ microservices)
         │ Services│ Trip, Payment, User,
         │         │ Driver, Notification
         └────┬────┘
              │
         ┌────┴────┐
         │ Data    │
         │ Platform│ Schemaless (MySQL), Cassandra,
         │         │ Kafka, Redis, HDFS
         └─────────┘
```

## Key Lessons

| Technology | Use |
|------------|-----|
| **Schemaless** | MySQL-based key-value store |
| **Ringpop** | Consistent hashing for service discovery |
| **Cadence** | Workflow orchestration engine |
| **Kafka** | Event-driven architecture |
| **H3** | Hexagonal geospatial indexing |
| **Self-driving** | No manual infrastructure management |

## Interview Questions
1. How does Uber match riders with drivers?
2. How does Uber's surge pricing work?
3. How does Uber handle geospatial queries at scale?
4. What was Schemaless and why did Uber build it?
5. Design a simplified Uber ride-matching system
