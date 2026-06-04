# MySQL

## Definition
MySQL is a popular open-source relational database management system known for its speed, reliability, and ease of use. It's the "M" in the LAMP stack and powers many of the world's largest websites.

## Real-World Example
**Uber**: Originally built on MySQL, Uber used MySQL with schemaless (a key-value layer on top of MySQL) to handle their massive scale before migrating to their own DocStore.

## Key Features

| Feature | Description |
|---------|-------------|
| **Storage Engines** | InnoDB (default), MyISAM, Memory, etc. |
| **Replication** | Built-in master-slave, group replication |
| **Partitioning** | Range, list, hash, key partitioning |
| **Full-text indexes** | InnoDB supports full-text search |
| **JSON support** | JSON data type with indexing |
| **Stored procedures** | Server-side logic |
| **Triggers** | Automated actions on data changes |

## Architecture

```
 ┌──────────────────────────────────────────────────────┐
 │                  MySQL Architecture                   │
 ├──────────────────────────────────────────────────────┤
 │                                                       │
 │  ┌──────────────┐      ┌──────────────┐             │
 │  │  Client 1    │      │  Client 2    │             │
 │  └──────┬───────┘      └──────┬───────┘             │
 │         │                     │                      │
 │  ┌──────▼─────────────────────▼───────┐             │
 │  │         Connection Pool              │             │
 │  │       (thread per connection)       │             │
 │  └────────────────┬────────────────────┘             │
 │                   │                                  │
 │  ┌────────────────▼────────────────────┐             │
 │  │         SQL Interface                │             │
 │  │   Query Cache (deprecated in 8.0)   │             │
 │  └────────────────┬────────────────────┘             │
 │                   │                                  │
 │  ┌────────────────▼────────────────────┐             │
 │  │          Query Optimizer             │             │
 │  │      Cost-based optimization        │             │
 │  └────────────────┬────────────────────┘             │
 │                   │                                  │
 │  ┌────────────────▼────────────────────┐             │
 │  │         Storage Engine              │             │
 │  │   ┌─────────┐  ┌─────────┐         │             │
 │  │   │ InnoDB  │  │ MyISAM  │         │             │
 │  │   │ (default)│  │ (legacy)│         │             │
 │  │   └─────────┘  └─────────┘         │             │
 │  └────────────────┬────────────────────┘             │
 │                   │                                  │
 │  ┌────────────────▼────────────────────┐             │
 │  │           Disk Storage               │             │
 │  │      Tablespaces, Redo Log, Binlog  │             │
 │  └─────────────────────────────────────┘             │
 │                                                       │
 └──────────────────────────────────────────────────────┘
```

## InnoDB vs MyISAM

| Feature | InnoDB | MyISAM |
|---------|--------|--------|
| ACID | ✅ (full) | ❌ |
| Transactions | ✅ | ❌ |
| Foreign keys | ✅ | ❌ |
| Row-level locking | ✅ | ❌ (table-level) |
| Full-text indexes | ✅ (5.6+) | ✅ |
| Compression | ✅ | ❌ |
| Crash recovery | ✅ (automatic) | ❌ (manual repair) |
| MVCC | ✅ | ❌ |
| Primary key | Clustered | Non-clustered |

## Replication

```
Asynchronous:
  Master ──► Binlog ──► Slave I/O Thread ──► Relay Log ──► Slave SQL Thread

Semi-Synchronous:
  Master ──► Binlog ──► Slave ←── Ack ──► Transaction committed
  (Waits for at least one slave to acknowledge)

Group Replication:
  Multi-master, built-in conflict detection
  Paxos-based consensus
```

## MySQL Indexes

| Index Type | Description |
|------------|-------------|
| **B-Tree** | Default, balanced tree for equality/range |
| **Hash** | Memory engine only |
| **Full-text** | Text search |
| **Spatial** | R-tree for geospatial data |
| **Composite** | Multiple columns, leftmost prefix rule |
| **Covering** | All columns in index, no table access |
| **Descending** | 8.0+ support for DESC indexes |
| **Invisible** | Hidden from optimizer, useful for testing |

## Advantages
- Fast read performance
- Simple to set up and manage
- Widely supported (every hosting provider)
- Large ecosystem and community
- Good for read-heavy workloads

## Disadvantages
- Limited ACID compliance (depends on engine)
- No full parallel query execution
- Replication is asynchronous by default
- Query optimizer weaker than PostgreSQL
- DDL operations can be blocking

## MySQL in Production

```
Connection Pooling:    ProxySQL, MySQL Router, HAProxy
High Availability:     InnoDB Cluster, Orchestrator, MHA
Backup:               mysqldump, XtraBackup, mysqlpump
Monitoring:           PMM (Percona Monitoring), MySQL Enterprise Monitor
Sharding:             Vitess, MySQL Fabric, ProxySQL
Full-text search:     Built-in (InnoDB)
Time-series:          None built-in
Load balancing:       ProxySQL, HAProxy, LVS
```

## MySQL vs PostgreSQL

| Comparison | MySQL | PostgreSQL |
|------------|-------|------------|
| ACID | InnoDB only | Full by default |
| CTEs | 8.0+ support | Excellent |
| Indexing | B-tree + more | B-tree, GiST, GIN, BRIN |
| JSON | Limited indexing | Full JSONB with GIN |
| Concurrency | MVCC (different impl) | MVCC |
| Replication | Async, semi-sync, group | Streaming, logical |
| Extensions | Pluggable storage | Extension ecosystem |
| License | GPL/Commercial | PostgreSQL license |

## Interview Questions
1. What are the differences between InnoDB and MyISAM?
2. How does MySQL replication work?
3. What is the N+1 query problem and how to fix it in MySQL?
4. How does MySQL's query cache work (and why was it removed)?
5. Compare MySQL and PostgreSQL for a new project
