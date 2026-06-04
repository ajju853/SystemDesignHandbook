# Design TinyURL

## Problem
Design a URL shortening service like TinyURL.

## Requirements
- Generate short, unique URLs
- Redirect to original URL
- ~100M URLs/month
- Custom alias support
- Analytics (click count, referrer)

## Solution Framework

### Capacity
```
Writes: 100M/month = ~38/s
Reads: 1B redirects/month = ~380/s
Storage: ~50GB (10 years)
Short code: 7 chars base62 = 3.5T combinations
```

### High-Level Design

```
Client ──► Write API ──► Short Code Generator ──► DB
Client ──► Read API  ──► Cache (Redis) ──► DB (miss)
```

### Key Decision Points

| Decision | Options | Choice |
|----------|---------|--------|
| Short code | Hash vs random vs sequential | Base62 encoded Snowflake ID |
| Database | SQL vs NoSQL | PostgreSQL (transactions, ACID) |
| Cache | Redis vs Memcached | Redis (data structures, TTL) |
| Redirect | 301 vs 302 | 301 (permanent) for most, 302 for analytics |

### Interview Discussion Points
1. How to handle concurrent writes to the same custom alias?
2. How to scale redirects (CDN, edge caching)?
3. How to prevent malicious URLs?
4. How to generate unique IDs across servers?
