# PostgreSQL

## Definition
PostgreSQL is an advanced, open-source relational database management system (RDBMS) known for its reliability, feature robustness, and standards compliance. It supports both SQL and JSON queries, making it a hybrid relational/document database.

## Real-World Example
**Instagram**: Uses PostgreSQL as their primary database, sharded across thousands of servers. They chose PostgreSQL for its reliability, extensibility, and strong consistency guarantees.

## Key Features

| Feature | Description |
|---------|-------------|
| **ACID Compliance** | Full atomicity, consistency, isolation, durability |
| **MVCC** | Multi-Version Concurrency Control for concurrent access |
| **Extensibility** | Custom data types, operators, index types, functions |
| **Full-text search** | Built-in search engine (tsvector/tsquery) |
| **JSON/JSONB** | NoSQL document storage with indexing |
| **Replication** | Streaming, logical, synchronous, cascading |
| **Partitioning** | Range, list, hash partitioning |
| **Foreign Data Wrappers** | Connect to external data sources |

## Architecture

```
 ┌──────────────────────────────────────────────────────┐
 │                PostgreSQL Architecture                │
 ├──────────────────────────────────────────────────────┤
 │                                                       │
 │  ┌──────────────┐      ┌──────────────┐             │
 │  │  Client 1    │      │  Client 2    │             │
 │  └──────┬───────┘      └──────┬───────┘             │
 │         │                     │                      │
 │  ┌──────▼─────────────────────▼───────┐             │
 │  │          Connection Manager          │             │
 │  │    (fork per connection, ~2-10MB)   │             │
 │  └────────────────┬────────────────────┘             │
 │                   │                                  │
 │  ┌────────────────▼────────────────────┐             │
 │  │           Query Processor            │             │
 │  │  Parser → Rewrite → Planner → Execute│             │
 │  └────────────────┬────────────────────┘             │
 │                   │                                  │
 │  ┌────────────────▼────────────────────┐             │
 │  │         Shared Buffers (cache)       │             │
 │  └────────────────┬────────────────────┘             │
 │                   │                                  │
 │  ┌────────────────▼────────────────────┐             │
 │  │              WAL (Write-Ahead Log)   │             │
 │  │          Sequential, append-only     │             │
 │  └────────────────┬────────────────────┘             │
 │                   │                                  │
 │  ┌────────────────▼────────────────────┐             │
 │  │           Data Files (heap)          │             │
 │  │    /var/lib/postgresql/data/base/   │             │
 │  └─────────────────────────────────────┘             │
 │                                                       │
 └──────────────────────────────────────────────────────┘
```

## Query Processing Pipeline

```
SQL Query
    │
    ▼
┌──────────┐     Parse SQL into parse tree
│  Parser  │     Check syntax, build AST
└────┬─────┘
     │
     ▼
┌──────────┐     Transform rules/views
│ Rewriter │     Apply system rules
└────┬─────┘
     │
     ▼
┌──────────┐     Generate execution plans
│ Planner  │     Cost-based optimization (CBO)
│          │     Considers indexes, statistics
└────┬─────┘
     │
     ▼
┌──────────┐     Execute plan
│ Execute  │     Read/write data
└──────────┘     Return results
```

## Indexes

| Index Type | Use Case |
|------------|----------|
| **B-tree** | Default — equality and range queries |
| **Hash** | Equality queries only |
| **GiST** | Full-text search, geometric data |
| **GIN** | Array values, JSONB, full-text |
| **BRIN** | Large, naturally ordered tables |
| **SP-GiST** | Clustered data, multi-dimensional |

## Replication

```
Synchronous (no data loss):
  Write ──► Primary ──sync─► Standby ──► Ack ──► Client

Asynchronous (fast, slight delay):
  Write ──► Primary ──► Client ✓
              │ async
              ▼
           Standby (seconds behind)

Cascading:
  Primary ──► Standby 1 ──► Standby 2 ──► Standby 3
```

## Advantages
- Full ACID compliance
- Excellent SQL standards compliance
- Rich extension ecosystem (PostGIS, TimescaleDB, pgvector)
- Strong consistency
- MVCC for concurrent access
- Mature and battle-tested (30+ years)

## Disadvantages
- Lower write throughput vs NoSQL
- Vertical scaling for write-heavy workloads
- Replication lag with async replication
- Complex configuration for high performance
- Larger memory footprint than MySQL

## PostgreSQL in Production

```
Connection Pooling:    PgBouncer, Pgpool-II
High Availability:     Patroni, repmgr
Backup:               pg_dump, pgBackRest, WAL-G
Monitoring:           pg_stat_statements, pgBadger
Sharding:             Citus (CitusData), built-in partitioning
Full-text search:     Built-in
Vector search:        pgvector extension
Time-series:          TimescaleDB extension
```

## Interview Questions
1. How does PostgreSQL's MVCC work?
2. Compare PostgreSQL and MySQL for a high-write workload
3. How does PostgreSQL handle concurrency without read locks?
4. What is VACUUM in PostgreSQL and why is it needed?
5. Explain PostgreSQL's WAL and its role in crash recovery
