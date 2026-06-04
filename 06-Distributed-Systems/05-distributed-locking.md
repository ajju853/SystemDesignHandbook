# Distributed Locking

## Definition
Distributed locking ensures mutual exclusion across multiple processes running on different machines. Only one process can hold the lock at any time.

## Why Redlock Fails
Martin Kleppmann's analysis: Redlock has no fencing mechanism. A delayed lock holder can corrupt shared state.

**Better approach**: Use a single, strongly consistent store with fencing tokens.

## Implementation

### Redis (SETNX)
```python
lock_key = f"lock:resource:{resource_id}"

# Acquire (with TTL to handle crashes)
acquired = cache.setnx(lock_key, token, ttl=30)

if acquired:
    try:
        process_resource(resource_id)
    finally:
        # Release only if still our lock
        if cache.get(lock_key) == token:
            cache.delete(lock_key)
```

### ZooKeeper ephemeral znode
Clients create ephemeral znodes. If client fails, znode disappears.

## Fencing Tokens

```
Lock Service ──► Token: 5 ──► Client A (acquires lock)
                                   │ (delayed)
                                   ▼
Lock Service ──► Token: 6 ──► Client B (acquires lock)
                                   
Client A wakes up, writes with token: 5 ← Rejected! Token stale
Client B writes with token: 6 ← Accepted
```

## Interview Questions
1. What's the problem with Redis Redlock?
2. How do fencing tokens prevent data corruption?
3. When would you use ZooKeeper vs Redis for distributed locking?
4. How does a distributed lock handle the "lock holder crashes" scenario?
5. Design a distributed lock service
