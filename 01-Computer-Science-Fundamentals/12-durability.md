# Durability

## Definition
Durability is the guarantee that once a transaction is committed, it will remain committed even in the event of power loss, crashes, or errors. The data is permanently stored and recoverable.

## Real-World Example
**AWS S3**: Designed for 99.999999999% durability (11 nines). If you store 10 billion objects, you can expect to lose one object every 10,000 years. This is achieved through automatic replication across multiple facilities.

## Durability vs Other Properties

| Property | Question |
|----------|----------|
| **Consistency** | "Do all nodes see the same data?" |
| **Availability** | "Is the system reachable?" |
| **Durability** | "Is the data still there after a crash?" |
| **Reliability** | "Does the system produce correct results?" |

## Durability Mechanisms

### 1. Write-Ahead Log (WAL)
```
Transaction ──► 1. Write to WAL (disk) ──► 2. Apply to data (memory)
                                               │
                                          Crash here? 
                                               │
                                          Recovery: replay WAL
```

### 2. Replication
```
Write ──► Primary ──sync─► Replica 1
                 ──sync─► Replica 2
                 ──sync─► Replica 3
```

### 3. Checkpointing
```
State ──► Periodically save checkpoint ──► If crash, restore from checkpoint
```

### 4. RAID (Redundant Array of Independent Disks)
```
RAID 1: Mirror data across two disks
RAID 5: Striping + parity (tolerate 1 disk failure)
RAID 6: Striping + dual parity (tolerate 2 disk failures)
```

## Durability Levels

| Level | Description | MTBF | Example |
|-------|-------------|------|---------|
| **Single disk** | No redundancy | 3-5 years | Laptop SSD |
| **RAID 1** | Mirror across 2 disks | 10+ years | Database server |
| **Multi-AZ** | Replicate across DCs | 100+ years | RDS Multi-AZ |
| **Multi-Region** | Replicate across regions | 1000+ years | S3 Cross-Region |
| **11 nines** | Erasure coding + replication | 10,000+ years | S3 Standard |

## Durability in Practice

### Database Durability (ACID - D)
```sql
-- WAL mode in PostgreSQL
BEGIN;
  UPDATE accounts SET balance = balance - 100 WHERE id = 1;
  UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;  -- WAL flushed to disk BEFORE commit returns
```

### Message Queue Durability
```
Producer ──► Kafka Topic ──► Partition 0 ──► Disk
                                replication.factor=3
                                │
                    ┌───────────┼───────────┐
                    ▼           ▼           ▼
                [Broker 1]  [Broker 2]  [Broker 3]
                (Leader)    (Follower)  (Follower)
```

## Diagram: Durability Chain

```
Write Request
    │
    ▼
┌─────────────────────┐
│  Application Memory  │  ──► Volatile (lost on crash)
└─────────┬───────────┘
          │ fsync()
          ▼
┌─────────────────────┐
│  OS Page Cache       │  ──► Still volatile
└─────────┬───────────┘
          │ fsync()
          ▼
┌─────────────────────┐
│  Disk Write Buffer   │  ──► Hardware cache (battery-backed)
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│  Magnetic Platter    │  ──► Durable
│  / Flash Memory     │
└─────────────────────┘
```

## Interview Questions
1. How does PostgreSQL's WAL ensure durability?
2. What's the difference between durability and availability?
3. Design a system that guarantees 99.999999999% durability
4. How does Kafka achieve durability while maintaining high throughput?
5. What happens when a database crashes before fsync completes?
