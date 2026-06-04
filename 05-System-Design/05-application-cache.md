# Application Cache

## Definition
Application-level caching stores data in the application's memory space, avoiding network calls and database queries for frequently accessed data.

## Real-World Example
**Google Search**: Caches search result snippets and autocomplete suggestions in memory. The in-memory cache handles 80%+ of queries with sub-millisecond latency before hitting the search index.

## Cache Layers

```
┌──────────────────────────────────────────────┐
│         Cache Layer Architecture              │
├──────────────────────────────────────────────┤
│                                               │
│  L1: In-Process Cache (local heap)           │
│      • Guava Cache, Caffeine, ConcurrentHashMap │
│      • ~20-50ns access                       │
│      • Limited by JVM heap                   │
│      • Data is local to instance             │
│                                               │
│  L2: Distributed Cache (external)            │
│      • Redis, Memcached                      │
│      • ~1-5ms access                         │
│      • Shared across instances               │
│      • Scales horizontally                   │
│                                               │
│  L3: Database (fallback)                     │
│      • PostgreSQL, MySQL, etc.               │
│      • ~10-100ms access                      │
│      • Source of truth                       │
│                                               │
└──────────────────────────────────────────────┘
```

## Local Cache Libraries

| Library | Language | Features |
|---------|----------|----------|
| Caffeine | Java | High-performance, near-optimal hit rate |
| Guava Cache | Java | Multi-threaded, TTL, LRU |
| Ehcache | Java | Disk overflow, clustering |
| lru-cache | JavaScript | Simple LRU, configurable |
| cachetools | Python | Decorators, TTL, LFU |

## Interview Questions
1. When would you use application-level cache vs Redis?
2. How do you handle cache invalidation across multiple application instances?
3. What's the difference between local and distributed cache?
4. Design a multi-layer cache for a high-traffic API
5. How does Caffeine achieve better hit rates than Guava Cache?
