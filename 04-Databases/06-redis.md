# Redis

## Definition
Redis (Remote Dictionary Server) is an open-source, in-memory data structure store used as a database, cache, message broker, and streaming engine. It supports strings, hashes, lists, sets, sorted sets, bitmaps, hyperloglogs, geospatial indexes, and streams.

## Real-World Example
**Twitter**: Uses Redis for caching user timelines, rate limiting, and real-time analytics. Redis handles millions of operations per second to serve tweets to 500M+ users with sub-millisecond latency.

## Data Structures

```redis
# String (caching, counters)
SET user:123:name "Alice"
GET user:123:name          # "Alice"
INCR page:views            # 42

# Hash (objects)
HSET user:123 name "Alice" age 30 city "SF"
HGET user:123 name         # "Alice"
HGETALL user:123           # all fields

# List (queues, timelines)
LPUSH recent:posts "post:1"
LPUSH recent:posts "post:2"
LRANGE recent:posts 0 9    # last 10 posts

# Set (unique items, tags)
SADD post:1:tags "redis" "database"
SMEMBERS post:1:tags       # ["redis", "database"]
SISMEMBER post:1:tags "redis"  # 1 (true)

# Sorted Set (leaderboards, rate limits)
ZADD leaderboard 1000 "alice"
ZADD leaderboard 950 "bob"
ZREVRANGE leaderboard 0 9 WITHSCORES  # top 10

# Stream (message queue, event log)
XADD events * type "login" user "alice"
XRANGE events - + COUNT 10
```

## Architecture

```
 ┌──────────────────────────────────────────────┐
 │              Redis Architecture               │
 ├──────────────────────────────────────────────┤
 │                                                │
 │  ┌──────────────┐    ┌──────────────┐        │
 │  │  Client 1    │    │  Client 2    │        │
 │  └──────┬───────┘    └──────┬───────┘        │
 │         │                   │                  │
 │  ┌──────▼───────────────────▼───────┐        │
 │  │        TCP Connection Handler      │        │
 │  └────────────────┬──────────────────┘        │
 │                   │                            │
 │  ┌────────────────▼──────────────────┐        │
 │  │         Command Processor           │        │
 │  │   Single-threaded event loop       │        │
 │  │   ~100K-1M ops/sec                │        │
 │  └────────────────┬──────────────────┘        │
 │                   │                            │
 │  ┌────────────────▼──────────────────┐        │
 │  │         Data Store                 │        │
 │  │  (In-memory hash table of keys)   │        │
 │  └────────────────┬──────────────────┘        │
 │                   │                            │
 │  ┌────────────────▼──────────────────┐        │
 │  │          Persistence               │        │
 │  │  RDB (snapshot) / AOF (append)    │        │
 │  └───────────────────────────────────┘        │
 │                                                │
 └──────────────────────────────────────────────┘
```

## Persistence Options

| Option | Description | Durability | Performance |
|--------|-------------|------------|-------------|
| **RDB** (snapshot) | Point-in-time dump | Loss of last snapshot | Good |
| **AOF** (append-only) | Every write logged | Very durable | Slower |
| **RDB + AOF** | Both | Best | Moderate |
| **None** | Not persistent | No durability | Best |

## Redis in Production

### Sentinel (High Availability)

```
┌──────────────┐
│  Sentinel 1  │──┐
└──────────────┘  │
┌──────────────┐   ├── Monitor, notify, failover
│  Sentinel 2  │──┘
└──────────────┘
┌──────────────┐
│  Sentinel 3  │  (quorum for election)
└──────────────┘

Master ──► Replica 1 ──► Replica 2
                │
     (failover to Replica if Master fails)
```

### Cluster (Sharding)

```
┌─────────────────────────────────────────────────┐
│                   Redis Cluster                   │
├─────────────────────────────────────────────────┤
│                                                   │
│  Nodes: 6 (3 masters, 3 replicas)                │
│  Slots: 16384 (partitioned across masters)        │
│                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │ Master A │  │ Master B │  │ Master C │      │
│  │ 0-5460   │  │ 5461-10922│ │ 10923-16383│    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘      │
│       │              │              │             │
│  ┌────▼─────┐  ┌────▼─────┐  ┌────▼─────┐      │
│  │ Replica A│  │ Replica B│  │ Replica C│      │
│  └──────────┘  └──────────┘  └──────────┘      │
└─────────────────────────────────────────────────┘
```

## Advantages
- Extremely fast (sub-millisecond)
- Rich data structures
- Built-in replication and clustering
- Pub/Sub for messaging
- Lua scripting
- TTL/expiry for cache management
- Wide ecosystem support

## Disadvantages
- In-memory (RAM cost, dataset size limited)
- Single-threaded (blocking on slow commands)
- No query language (no filtering beyond keys)
- No strong consistency guarantees
- AOF can grow large
- No security by default (no auth, no SSL)

## Common Use Cases

| Use Case | Data Structure | Example |
|----------|---------------|---------|
| **Cache** | String, Hash | Session data, API responses |
| **Rate limiter** | Sorted Set, String | 100 req/min per user |
| **Leaderboard** | Sorted Set | Top scores, rankings |
| **Message queue** | List, Stream | Job queues, pub/sub |
| **Session store** | String (JSON) | User sessions |
| **Real-time analytics** | HyperLogLog, Bitmap | Unique visitors, daily active users |
| **Distributed lock** | String (SETNX) | Mutual exclusion |
| **Geospatial** | Geo (Sorted Set) | Nearby places |

## Interview Questions
1. How does Redis achieve single-threaded performance?
2. Compare Redis vs Memcached for caching
3. How does Redis persistence work (RDB vs AOF)?
4. What is Redis Sentinel and how does failover work?
5. How would you design a rate limiter using Redis?
