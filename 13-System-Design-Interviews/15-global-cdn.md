# Design a Global CDN

## Requirements

- Serve content globally with < 50ms p95 latency
- Cache static and dynamic content
- 10 Tbps peak throughput
- Instant cache purging (< 1s)
- Edge compute for request modification
- DDoS protection at edge
- 5000+ edge locations globally

## Capacity Estimation

```
Throughput:     10 Tbps peak
Requests/sec:   100M req/sec peak
Edge locations: 5000+
Cache size:     50PB total (100GB-10TB per edge)
Purge:          10K purge requests/sec
Edge compute:   10M function invocations/sec
DNS queries:    5M queries/sec
Origin shield:  10Gbps per shield region
```

## High-Level Design

```mermaid
graph TB
    subgraph Edge["Edge Tier (5000+ PoPs)"]
        User[User] --> DNS[DNS - Route to Nearest PoP]
        DNS --> LB[L4 Load Balancer]
        LB --> Edge_Cache[Edge Cache - RAM + NVMe]
        Edge_Cache --> Edge_Compute[Edge Compute (V8 Isolate)]
        
        subgraph EdgeCacheOps["Edge Cache Operations"]
            Edge_Cache --> Hit[HIT: Serve from cache]
            Edge_Cache --> Miss[MISS: Request parent tier]
        end
    end
    
    subgraph Parent["Parent Tier (200+ Shield PoPs)"]
        Miss --> Shield[Shield Cache - Larger Storage]
        Shield --> Shield_Compute[Shield Compute]
        Shield --> Origin[Origin Pull]
    end
    
    subgraph Origin["Origin Tier"]
        Origin --> OriginSvc[Origin Server / S3 / GCS]
        Origin --> Dyn[Dynamic Content - API Origin]
    end
    
    subgraph Control["Control Plane"]
        Config[Configuration Service] --> Edge_Cache
        Config --> Shield
        Purge[Purge API] --> Purge_Q[Purge Queue]
        Purge_Q --> Edge_Cache
        Purge_Q --> Shield
    end
```

## Cache Hierarchy

```
Request Flow:
  1. User → DNS → nearest edge PoP (< 1ms routing)
  2. Edge PoP checks RAM cache (~100GB per server)
     → HIT: return in < 5ms
     → MISS: check NVMe cache (~1TB per server)
     → HIT: return in < 10ms
     → MISS: forward to Shield PoP
  3. Shield PoP (1 per region, 200 globally)
     → Larger cache (~100TB), absorbs origin traffic
     → MISS: fetch from origin
  4. Origin response flows back:
     → Shield caches it
     → Edge caches it (leaving room for popular content)
     
TTL Hierarchy:
  - Static assets (JS/CSS/images): max-age 1 year, CDN caches indefinitely
  - HTML pages: max-age 5 min, CDN revalidates with ETag
  - API responses: max-age 0, CDN uses stale-while-revalidate (1 min)
```

## Cache Invalidation (Instant Purge)

```
Purge Architecture:
  1. Client sends purge request: PURGE /path/to/content
  2. Purge Service validates API key, checks permissions
  3. Purge request published to global purge queue (Kafka)
  4. Each edge PoP consumer processes purge within 500ms
  5. Cache entry marked as stale, next request re-fetches

Optimizations:
  - Purge by URL: single file
  - Purge by tag: Surrogate-Key header for group purge
    Purge-Tag: product-123 → invalidates all product-123 tagged content
  - Purge by host: wildcard *.example.com
  
Scalability:
  - 10K purge requests/sec
  - Kafka partitions by purge key hash
  - Edge nodes subscribe to relevant partitions only
```

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Edge compute** | V8 isolates (not containers) | 10x denser than Lambda@Edge, cold start < 1ms |
| **Storage hierarchy** | RAM → NVMe → Shield → Origin | Cost-performance curve: RAM expensive, origin slow |
| **Routing** | Anycast + BGP | Single IP, routed to nearest PoP |
| **Purge** | Kafka-based with tag-level invalidation | Instant purge, group invalidation |
| **DDoS** | L3/L4 filtering at edge, L7 WAF | Absorb attacks before they reach origin |
| **Origin shield** | 200 regional shield PoPs | 90%+ cache hit rate at shield, origin almost untouched |

## Interview Questions

1. How does a CDN route users to the nearest edge location?
2. How does cache invalidation work across 5000+ edge nodes?
3. How does edge computing differ from serverless?
4. How does a CDN protect against DDoS attacks?
5. Design the cache hierarchy for cost-performance optimization
