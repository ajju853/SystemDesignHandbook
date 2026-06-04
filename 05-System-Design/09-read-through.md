# Read Through Pattern

## Definition
Read Through is similar to Cache Aside, but the cache itself is responsible for loading data from the database on a miss. The application code only talks to the cache.

## Flow Diagram

```
Application                    Cache                    Database
    │                           │                         │
    ├── GET(key) ──────────────►│                         │
    │                           ├── Cache Hit ───► Return │
    │                           │                         │
    │                           ├── Cache Miss ──────────►│
    │                           │◄──── Data ──────────────│
    │                           ├── Store & Return        │
    │◄──── Value ──────────────│                         │
```

## Code Example

```python
from django.core.cache import cache

class UserCache:
    """Read-through cache example"""
    
    def get_user(self, user_id):
        key = f"user:{user_id}"
        
        # Cache loader function (called on miss)
        def load_user():
            return db.query("SELECT * FROM users WHERE id = ?", user_id)
        
        # get_or_set handles read-through
        return cache.get_or_set(key, load_user, timeout=3600)
```

## Advantages
- Clean application code (only talks to cache)
- Consistent caching behavior
- Easier to monitor cache hit/miss ratios
- Cache can be swapped without application changes

## Disadvantages
- Cache implementation is more complex
- Cache provider must support read-through (Redis doesn't natively)
- Cache stampede handling needed

## Interview Questions
1. How does read-through differ from cache aside?
2. Which caches support native read-through?
3. How do you handle cache stampede with read-through?
4. When would you prefer read-through over cache aside?
5. Design a read-through cache for a product catalog
