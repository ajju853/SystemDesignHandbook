# Write Through Pattern

## Definition
Write Through writes data to both the cache and the database synchronously. The write is not considered successful until both writes complete.

## Flow Diagram

```
Write Request
       │
       ▼
Write to Cache ───► Write to Database
       │                    │
       ▼                    ▼
   Cache OK              DB OK
       │                    │
       └────────┬──────────┘
                │
                ▼
          Return Success
```

## Code Example

```python
def update_user(user_id, data):
    key = f"user:{user_id}"
    
    # Write to cache first
    cache.set(key, data)
    
    # Then write to database
    db.execute("UPDATE users SET name = ? WHERE id = ?",
               data['name'], user_id)
    
    return {"success": True}
```

## Advantages
- Read is always fast (never stale)
- Cache is always consistent with database
- No cache miss on first read

## Disadvantages
- Higher write latency (two writes)
- Wasted writes for infrequently read data
- Cache failure blocks writes (single point of failure)

## Interview Questions
1. Compare write-through vs cache-aside for read-heavy workloads
2. What happens if the cache write succeeds but database write fails?
3. When would you use write-through instead of write-behind?
4. How does write-through affect write throughput?
5. Design a system using write-through for a stock inventory system
