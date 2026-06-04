# RDS & Databases

## Definition
Amazon RDS (Relational Database Service) is a managed service that makes it easy to set up, operate, and scale relational databases in the cloud. It handles database setup, patching, backup, and failover.

## RDS Engines

| Engine | Strengths | Best For |
|--------|-----------|----------|
| **Aurora MySQL** | 5x faster than MySQL, auto-scaling storage | High-performance web apps |
| **Aurora PostgreSQL** | 3x faster than PostgreSQL, Multi-AZ | Enterprise, complex queries |
| **PostgreSQL** | Rich extensions (PostGIS, TimescaleDB) | Geospatial, time-series |
| **MySQL** | Proven, widely supported, cheaper | Standard web applications |
| **MariaDB** | MySQL-compatible, more storage engines | Drop-in MySQL replacement |
| **SQL Server** | Windows integration, .NET ecosystem | Enterprise .NET apps |
| **Oracle** | Advanced security, legacy compatibility | Existing Oracle workloads |

## RDS Key Features

| Feature | Description | Use Case |
|---------|-------------|----------|
| **Multi-AZ** | Synchronous standby in another AZ | Automatic failover on AZ failure |
| **Read Replicas** | Up to 15 async replicas | Scale read-heavy workloads |
| **Automated Backups** | Point-in-time recovery within retention window | Data recovery |
| **Performance Insights** | Real-time DB load visualization | Identify slow queries |
| **RDS Proxy** | Connection pooling for Lambda | Prevent connection exhaustion |
| **Aurora Auto Scaling** | Read replicas grow/shrink with load | Serverless read scaling |

## Aurora Architecture vs Standard RDS

```
Standard RDS (Multi-AZ):
  Primary (AZ-A) ──sync replication──► Standby (AZ-B)
  Read Replica (AZ-C) ──async replication──► Primary

Aurora:
  Write: Primary (AZ-A) writes to 6 copies across 3 AZs
  Read: Aurora Replicas read from same storage (no copy)
  Failover: Promote replica in < 30 seconds
  
Key difference: Aurora decouples compute from storage.
Storage is a shared, auto-scaling cluster (10GB-128TB).
This means:
- Faster failover (no need to copy storage)
- No storage provisioning (grows as needed)
- Better durability (6 copies across 3 AZs)
```

## Interview Questions

1. What's the difference between Multi-AZ and Read Replicas?
2. How does Amazon Aurora differ from standard RDS MySQL?
3. How do you scale RDS for read-heavy workloads?
4. What is RDS Proxy and when should you use it?
5. Design a highly available database architecture with RDS
6. How does Aurora's storage work differently from standard RDS?
