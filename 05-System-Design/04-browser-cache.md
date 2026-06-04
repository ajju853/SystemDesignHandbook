# Browser Cache

## Definition
Browser caching stores web resources (HTML, CSS, JS, images) locally on the user's device. When a user revisits a page, resources can be loaded from the local cache instead of re-downloading.

## Real-World Example
**Google Chrome**: Caches 80%+ of resources locally. A returning visit to a news site loads ~100KB over network instead of 2MB — the rest comes from cache.

## Cache Headers

```http
# Strong caching — don't revalidate
Cache-Control: public, max-age=31536000, immutable

# Conditional — revalidate with server
Cache-Control: public, max-age=0, must-revalidate
ETag: "abc123"
Last-Modified: Wed, 15 Jan 2024 10:00:00 GMT

# No caching
Cache-Control: no-cache, no-store, must-revalidate
Pragma: no-cache
Expires: 0
```

## Cache Locations

```
Service Worker Cache (persistent, programmable)
    │
Memory Cache (fast, cleared on tab close)
    │
Disk Cache (slower, persists between sessions)
    │
Push Cache (HTTP/2, very short-lived)
```

## Interview Questions
1. How do Cache-Control and ETag headers work together?
2. What's the difference between max-age=0 and no-cache?
3. How does a Service Worker cache differ from HTTP cache?
4. Design a caching strategy for a single-page application
5. How do you force a browser to use updated resources?
