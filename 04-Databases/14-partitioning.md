# Database Partitioning

## Definition
Database partitioning divides a large table into smaller, more manageable pieces (partitions) while still treating it as a single logical table. Unlike sharding (distribution across servers), partitioning can happen within a single database instance.

## Real-World Example
**PostgreSQL time-series data**: A table storing 5 years of logs is partitioned by month. Queries for "last month's data" only scan one partition instead of the full table, improving query speed 10-100x.

## Partition Types

### Range Partitioning
```sql
CREATE TABLE orders (
    id SERIAL,
    order_date DATE,
    amount DECIMAL
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2024_q1 
    PARTITION OF orders 
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE orders_2024_q2 
    PARTITION OF orders 
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

-- Query automatically routed to correct partition
SELECT * FROM orders WHERE order_date = '2024-02-15';
-- Only scans orders_2024_q1
```

### List Partitioning
```sql
CREATE TABLE users (
    id SERIAL,
    name TEXT,
    region TEXT
) PARTITION BY LIST (region);

CREATE TABLE users_us 
    PARTITION OF users 
    FOR VALUES IN ('US', 'CA', 'MX');

CREATE TABLE users_eu 
    PARTITION OF users 
    FOR VALUES IN ('UK', 'DE', 'FR', 'IT');
```

### Hash Partitioning
```sql
CREATE TABLE logs (
    id SERIAL,
    message TEXT
) PARTITION BY HASH (id);

CREATE TABLE logs_0 
    PARTITION OF logs 
    FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE logs_1 
    PARTITION OF logs 
    FOR VALUES WITH (MODULUS 4, REMAINDER 1);
```

## Partition Pruning

```
Query: SELECT * FROM orders WHERE order_date = '2024-02-15'

Without partitioning:       With partitioning:
┌──────────────────────┐   ┌──────────────────────┐
│ orders               │   │ orders_2024_q1        │ ← scanned
│ (5 years of data)    │   │ orders_2024_q2        │ ← skipped
│                      │   │ orders_2024_q3        │ ← skipped
│ 10M rows scanned     │   │ orders_2024_q4        │ ← skipped
│ → slow               │   │ orders_2025_q1        │ ← skipped
└──────────────────────┘   └──────────────────────┘
                            100K rows scanned → fast!
```

## Partitioning vs Sharding

| Aspect | Partitioning | Sharding |
|--------|-------------|----------|
| Scope | Within single database | Across multiple databases |
| Transparency | Transparent to application | Requires awareness |
| Scaling | Vertical (same server) | Horizontal (more servers) |
| Complexity | Low | High |
| Cross-partition queries | Supported | Complex (scatter-gather) |

## Maintenance Operations

```sql
-- Add new partition
CREATE TABLE orders_2025_q1 
    PARTITION OF orders 
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');

-- Detach old partition (archive)
ALTER TABLE orders DETACH PARTITION orders_2023_q1;

-- Attach existing table as partition
ALTER TABLE orders ATTACH PARTITION orders_2023_q1
    FOR VALUES FROM ('2023-01-01') TO ('2023-04-01');
```

## When to Partition

```
Table Size > 1TB?              → Yes → Partition
Query performance degrading?   → Yes → Check if partition key aligns with queries
Time-series data?              → Yes → Range partition by time
Need to archive old data?      → Yes → Partition by time, detach old partitions
Large table with hotspots?     → Yes → Hash partition
```

## Interview Questions
1. What's the difference between partitioning and sharding?
2. How does partition pruning improve query performance?
3. When would you use range vs list vs hash partitioning?
4. How do you manage partition maintenance for time-series data?
5. Design a partitioning strategy for a multi-tenant SaaS application
