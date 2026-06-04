# Partitioning

## Definition
Partitioning (sharding) is the process of splitting a large dataset or system workload across multiple nodes, each responsible for a subset of the data. This enables horizontal scaling by distributing data and load.

## Real-World Example
**Instagram**: Uses database sharding to distribute user data across thousands of PostgreSQL instances. Each shard contains a range of user IDs, allowing the platform to scale to billions of users.

## Types of Partitioning

### Horizontal Partitioning (Sharding)
```
Table: users
┌────┬─────────┬─────────────┐
│ id │ name   │ email       │
├────┼─────────┼─────────────┤
│ 1  │ Alice  │ a@x.com     │  ──► Shard 0 (ids 1-1000)
│ 2  │ Bob    │ b@x.com     │
├────┼─────────┼─────────────┤
│ 1001 │ Charlie │ c@x.com   │  ──► Shard 1 (ids 1001-2000)
│ 1002 │ Diana  │ d@x.com   │
└────┴─────────┴─────────────┘
```

### Vertical Partitioning
```
Table: users (original)
┌────┬─────────┬─────────────┬────────────┬──────────┐
│ id │ name   │ email       │ bio        │ avatar   │
└────┴─────────┴─────────────┴────────────┴──────────┘

Table: user_profiles                  Table: user_auth
┌────┬─────────┬─────────────┐       ┌────┬──────┬──────────┐
│ id │ name   │ bio         │       │ id │email │ avatar   │
└────┴─────────┴─────────────┘       └────┴──────┴──────────┘
```

### Directory-Based Partitioning
```
Lookup Service:
  user_id 1-1000   ──► Shard 0
  user_id 1001-2000 ──► Shard 1
  user_id 2001-3000 ──► Shard 2
```

## Partitioning Strategies

### 1. Range-Based
```
Shard 0: user_id 1-10,000
Shard 1: user_id 10,001-20,000
Shard 2: user_id 20,001-30,000
```
**Pros**: Simple, supports range queries, easy to add shards
**Cons**: Risk of hotspots, uneven distribution

### 2. Hash-Based
```
shard_id = hash(user_id) % N

hash(1) % 4 = 1 ──► Shard 1
hash(2) % 4 = 2 ──► Shard 2
hash(3) % 4 = 3 ──► Shard 3
hash(4) % 4 = 0 ──► Shard 0
```
**Pros**: Even distribution, predictable
**Cons**: Range queries hit all shards, resharding is expensive

### 3. Consistent Hashing
```
Key space: 0 ──────────────────────────────────► 2^32
              [Node C]    [Node A]    [Node B]
                ▲            ▲            ▲
                │            │            │
           hash(C)       hash(A)       hash(B)

Key assigned to nearest clockwise node.
Adding/removing nodes only affects neighbors.
```
**Pros**: Minimal data movement on resharding, handles node addition/removal gracefully
**Cons**: Complexity, non-intuitive

### 4. Geographic
```
Region US:       users with region = 'us'
Region EU:       users with region = 'eu'
Region APAC:     users with region = 'apac'
```
**Pros**: Low latency for local users, data sovereignty compliance
**Cons**: Uneven distribution, complex cross-region queries

## Partitioning Tradeoffs

| Strategy | Distribution | Range Queries | Resharding | Complexity |
|----------|-------------|---------------|------------|------------|
| Range | Uneven | ✅ Good | ❌ Hard | ✅ Simple |
| Hash | Even | ❌ Poor | ❌ Hard | ⚠️ Medium |
| Consistent Hash | Even | ❌ Poor | ✅ Easy | ❌ Complex |
| Geographic | Uneven | ⚠️ Medium | ⚠️ Medium | ⚠️ Medium |

## Challenges with Partitioning

### Cross-Shard Queries
```
SELECT * FROM users JOIN orders ON users.id = orders.user_id
WHERE users.id = 1005 AND orders.id = 5003
-- Users: Shard 1, Orders: Shard 3
-- Requires scatter-gather or cross-shard join
```

### Resharding
```
Old: 4 shards ──► New: 8 shards
Each key: hash(key) % 4 ──► hash(key) % 8
Most keys move to different shards
Mitigation: Consistent hashing or double writes during migration
```

### Hotspots
```
Celebrity user on Shard 1 generates massive reads/writes
Mitigation: Split celebrity data across sub-shards, cache heavily
```

## Diagram: Partitioning Architecture

```
                    ┌──────────────────┐
                    │  Application     │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  Routing Layer   │
                    │  (Proxy/Router)  │
                    └──┬────┬────┬─────┘
                       │    │    │
              ┌────────┘    │    └────────┐
              ▼             ▼             ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │  Shard 0 │ │  Shard 1 │ │  Shard 2 │
        │  ids     │ │  ids     │ │  ids     │
        │  1-1000  │ │  1001-    │ │  ...     │
        └──────────┘ └──────────┘ └──────────┘
```

## Interview Questions
1. How would you shard a database for a social media platform?
2. What are the pros and cons of range vs hash-based partitioning?
3. How do you handle resharding without downtime?
4. What happens to cross-shard joins in a partitioned database?
5. Design a routing layer for a sharded database
