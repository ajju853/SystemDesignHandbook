# 03 — Databases

> The heart of every system. Understand how data is stored, queried, and scaled.

## Topic Tracks

### SQL Databases
| # | Topic | Description |
|---|-------|-------------|
| 1 | [PostgreSQL](01-postgresql.md) | Advanced relational database |
| 2 | [MySQL](02-mysql.md) | Popular open-source RDBMS |

### NoSQL Databases
| # | Topic | Description |
|---|-------|-------------|
| 3 | [MongoDB](03-mongodb.md) | Document-oriented NoSQL |
| 4 | [Cassandra](04-cassandra.md) | Wide-column distributed DB |
| 5 | [DynamoDB](05-dynamodb.md) | AWS managed NoSQL |
| 6 | [Redis](06-redis.md) | In-memory data store |
| 7 | [Elasticsearch](07-elasticsearch.md) | Search and analytics engine |

### Core Concepts
| # | Topic | Description |
|---|-------|-------------|
| 8 | [Indexing](08-indexing.md) | Fast data retrieval |
| 9 | [Sharding](09-sharding.md) | Horizontal data partitioning |
| 10 | [Replication](10-replication.md) | Data redundancy |
| 11 | [Transactions](11-transactions.md) | Atomic operations |
| 12 | [ACID](12-acid.md) | Database transaction guarantees |
| 13 | [BASE](13-base.md) | Alternative to ACID |
| 14 | [Partitioning](14-partitioning.md) | Data distribution strategies |
| 15 | [Query Optimization](15-query-optimization.md) | Performance tuning |

## Quick Reference

### SQL vs NoSQL

| Aspect | SQL | NoSQL |
|--------|-----|-------|
| Schema | Fixed (rigid) | Flexible (dynamic) |
| Relationships | Foreign keys | Embedded/Reference |
| ACID | Full support | Varies |
| Scaling | Vertical (mostly) | Horizontal (native) |
| Best for | Complex queries, consistency | High volume, flexible schema |

### Database Selection Guide

```
Need complex relationships & joins?
  ├── Yes ──► Need ACID?
  │            ├── Yes ──► PostgreSQL
  │            └── No ───► MySQL
  └── No ────► Need real-time analytics?
               ├── Yes ──► Elasticsearch
               └── No ────► Need high throughput writes?
                            ├── Yes ──► Cassandra
                            └── No ────► Need flexible documents?
                                         ├── Yes ──► MongoDB
                                         └── No ────► Need caching?
                                                      ├── Yes ──► Redis
                                                      └── No ────► DynamoDB
```

---

Previous: [02 — Networking](../02-Networking/README.md)
Next: [04 — Caching](../04-Caching/README.md)
