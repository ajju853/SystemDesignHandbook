# URL Shortener

## Requirements
- Generate short, unique URLs
- Redirect short URL to original
- Track click analytics
- Handle 100M URLs, 1B redirects/month
- Custom alias support
- TTL-based URL expiry

## Capacity Estimation
```
Traffic:
  Write: 100M URLs/month ≈ 38 URLs/sec
  Read: 1B redirects/month ≈ 380 reads/sec
  Ratio: 10:1 read/write

Storage (10 years):
  URL metadata: 100M × 500 bytes ≈ 50GB
  Analytics: 1B redirects × 200 bytes ≈ 200GB/year

Network:
  Ingress: 38 writes/sec × 1KB = 38KB/s
  Egress: 380 reads/sec × 1KB = 380KB/s
```

## API Design

```
POST /shorten
  Request:  { "url": "https://...", "custom_alias": "my-link", "ttl": 86400 }
  Response: { "short_url": "https://short.ly/abc123", "expires_at": "..." }

GET /{short_code}
  Response: 301 Redirect → original URL

GET /{short_code}/analytics
  Response: { "clicks": 1000, "top_referrers": [...], "daily": [...] }
```

## Database Design

```sql
CREATE TABLE urls (
    id BIGSERIAL PRIMARY KEY,
    short_code VARCHAR(7) UNIQUE NOT NULL,
    original_url TEXT NOT NULL,
    custom_alias VARCHAR(100) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    user_id BIGINT,
    INDEX idx_short_code (short_code),
    INDEX idx_user_id (user_id)
);

CREATE TABLE clicks (
    id BIGSERIAL PRIMARY KEY,
    url_id BIGINT REFERENCES urls(id),
    clicked_at TIMESTAMP DEFAULT NOW(),
    referrer TEXT,
    user_agent TEXT,
    ip_address INET,
    country VARCHAR(2),
    INDEX idx_url_id (url_id),
    INDEX idx_clicked_at (clicked_at)
) PARTITION BY RANGE (clicked_at);
```

## High-Level Design

```
Client ──► API Gateway ──► URL Service ──► PostgreSQL
              │                               │
              │                          ┌─────┴─────┐
              │                          │ Analytics  │
              │                          │ Service    │
              │                          └─────┬─────┘
              │                      Kafka      │
              │                    ┌────┴────┐   │
              │                    │Click Q  │   │
              │                    └─────────┘   │
              │                                 │
              │                          ┌──────┴──────┐
              └──────────────────────────│ Redis Cache  │
                                         └─────────────┘
```

## Short Code Generation

```python
# Base62 encoding (a-z, A-Z, 0-9 = 62 chars)
# 7 chars → 62^7 ≈ 3.5 trillion combinations

base62 = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

def encode(num):
    if num == 0:
        return base62[0]
    result = []
    while num > 0:
        result.append(base62[num % 62])
        num //= 62
    return ''.join(reversed(result))

# Use distributed unique ID (Snowflake) as input
short_code = encode(snowflake_id.generate())
```

## Scaling Strategy

| Component | Scale |
|-----------|-------|
| **URL Service** | Stateless, auto-scale with ALB |
| **PostgreSQL** | Master-slave, read replicas |
| **Redis** | Cluster mode, LRU eviction |
| **Analytics** | Kafka + batch processing (Spark) |
| **CDN** | CloudFront for redirect static assets |

## Deployment

```yaml
# docker-compose.yml
services:
  api:
    image: url-shortener:latest
    ports: ["8080:8080"]
    environment:
      DB_URL: postgresql://postgres:5432/urls
      REDIS_URL: redis://redis:6379
    depends_on: [postgres, redis]
  
  postgres:
    image: postgres:16
    volumes: ["pgdata:/var/lib/postgresql/data"]
  
  redis:
    image: redis:7
    command: redis-server --maxmemory 2gb --maxmemory-policy allkeys-lru
```

## Interview Questions
1. How would you generate unique short codes across multiple servers?
2. How do you handle custom alias conflicts?
3. How would you implement click analytics with minimal latency?
4. How do you prevent abuse (spam URLs, excessive creation)?
5. How would you design the redirect to be as fast as possible?
