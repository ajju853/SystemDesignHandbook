# Refresh Ahead Pattern

## Definition
Refresh Ahead (also called Write Around) proactively refreshes cache entries before they expire, based on predicted access patterns or configurable thresholds.

## Flow Diagram

```
Time ──────────────────────────────────────────────►
                                                    
          TTL Set: 3600s                           
          │                                         
          ▼                                         
     Cache Entry Created                            
          │                                         
          │        Refresh Trigger (TTL*0.8)       
          │              │                          
          ▼              ▼                          
┌─────────────────┐ ┌──────────┐                   
│ Active Cache     │ │ Refresh  │                   
│ (serving reads)  │ │ (async)  │                   
└─────────────────┘ └────┬─────┘                    
                         │                          
                         ▼                          
                   Fetch from DB                    
                         │                          
                         ▼                          
                  Update Cache                      
                   (new TTL)                        
```

## Code Example

```python
import threading
import time

class RefreshAheadCache:
    def __init__(self, cache_client, refresh_threshold=0.8):
        self.cache = cache_client
        self.refresh_threshold = refresh_threshold
    
    def get_or_refresh(self, key, loader_func, ttl=3600):
        # Check if we need to refresh
        ttl_remaining = self.cache.ttl(key)
        
        if ttl_remaining and ttl_remaining < ttl * (1 - self.refresh_threshold):
            # Trigger async refresh (don't block the reader)
            threading.Thread(
                target=self._refresh,
                args=(key, loader_func, ttl),
                daemon=True
            ).start()
        
        # Return current value (possibly stale if not refreshed yet)
        value = self.cache.get(key)
        if value:
            return value
        
        # Cache miss (shouldn't happen if refresh works)
        value = loader_func()
        self.cache.setex(key, ttl, value)
        return value
    
    def _refresh(self, key, loader_func, ttl):
        try:
            value = loader_func()
            self.cache.setex(key, ttl, value)
        except Exception as e:
            # Log error, serve stale data
            print(f"Refresh failed: {e}")
```

## Advantages
- Eliminates cache misses for predictable patterns
- Reduces perceived latency (users never wait)
- Smoothes database load (no refresh spikes)

## Disadvantages
- Wasted refreshes for unused data
- Increased cache hit ratio (may hide real issues)
- Requires prediction of access patterns
- More complex implementation

## Interview Questions
1. How does refresh ahead prevent cache stampedes?
2. When would you use refresh ahead vs standard TTL?
3. What happens if the refresh fails?
4. How do you determine which keys to refresh ahead?
5. Design a refresh-ahead strategy for a news website homepage
