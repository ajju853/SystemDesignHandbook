# Instagram Backend

## Requirements

- Photo/video uploads with filters
- Social graph (followers, following)
- Feed generation (chronological + algorithmic)
- Stories (ephemeral 24h content)
- Direct messaging
- 1B monthly users, 100M daily uploads

## Capacity Estimation

```
Uploads:        100M photos/day × 2MB = 200TB/day
Stories:        500M/day × 500KB = 250TB/day
Feed reads:     1B users × 50 refreshes/day = 50B reads/day
Likes:          5B/day
Follows:        2B edges in social graph
Storage:        200TB/day → 73PB/year (raw) → 15PB after compression
CDN egress:     ~100 Gbps peak
```

## API Design

```
POST /media/upload → {upload_url, media_id}
POST /media/configure → {media_id, caption, filters, location}
GET /media/{id} → {url, caption, likes_count, comments, ...}

POST /feed/timeline → (prefetch)
GET /feed?cursor=...&limit=30 → [media summaries]
GET /feed/stories?following=... → [story reels]

POST /users/{id}/follow / unfollow
GET /users/{id}/followers?cursor=...
GET /users/{id}/following?cursor=...

POST /media/{id}/like
POST /media/{id}/comment → {text}
```

## Database Design

```sql
-- Media
CREATE TABLE media (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    type VARCHAR(5) CHECK (type IN ('photo', 'video')),
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    caption TEXT,
    filter VARCHAR(30),
    width INT, height INT,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_user_created (user_id, created_at DESC)
);

-- Social Graph (fanout-on-read model for followers)
CREATE TABLE follows (
    follower_id UUID NOT NULL,
    followee_id UUID NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (follower_id, followee_id),
    INDEX idx_followee (followee_id, follower_id)
);

-- Likes
CREATE TABLE likes (
    user_id UUID NOT NULL,
    media_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (media_id, user_id)
);

-- Feed (fanout-on-write for active users)
CREATE TABLE feed_items (
    user_id UUID NOT NULL,   -- the viewer
    media_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, media_id DESC)
) PARTITION BY HASH (user_id);
```

## High-Level Design

```
┌──────────────────────────────────────────────────────────────┐
│                    Instagram Architecture                      │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│ Upload ──► Upload Service ──► S3 ──► CDN ──► Client          │
│                                                               │
│ Read ──► API Gateway ──► Feed Service                         │
│   │                │            │                             │
│   │           ┌────┴────┐  ┌────┴────┐                      │
│   │           │ Fanout  │  │ Cache   │                      │
│   │           │ Worker  │  │ (Redis) │                      │
│   │           └─────────┘  └─────────┘                      │
│   │                                                           │
│   └──► Social Graph ──► PostgreSQL + Cassandra               │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## Low-Level Design: Feed Generation

### Hybrid Approach

```python
# Fanout-on-write for active users (< 10K followers)
def create_post_for_active(user_id, media_id):
    followers = get_followers(user_id)
    for follower_id in followers:
        if is_active(follower_id):  # checks login recency
            redis.lpush(f"feed:{follower_id}", media_id)
            redis.ltrim(f"feed:{follower_id}", 0, 999)  # keep 1000 max

# Fanout-on-read for influencers (> 10K followers)
def create_post_for_influencer(user_id, media_id):
    # Store in a separate timeline
    redis.lpush(f"timeline:{user_id}", media_id)

def get_feed(viewer_id):
    # Merge from in-memory feed + pull from influencers the user follows
    feed = redis.lrange(f"feed:{viewer_id}", 0, 30)
    followees = get_followees(viewer_id)
    for f in followees:
        if is_influencer(f):
            posts = redis.lrange(f"timeline:{f}", 0, 5)
            feed.merge(posts)
    return rank_and_paginate(feed)
```

## Scaling Strategy

| Component | Strategy |
|-----------|----------|
| **Upload** | Presigned S3 URLs, async processing for filters/thumbnails |
| **Feed** | Hybrid fanout: write for active users, read for influencers |
| **Social Graph** | Cassandra (high write throughput for follows/unfollows) |
| **Likes** | Sharded counter in Redis (eventually consistent to DB) |
| **Stories** | Ephemeral storage (Redis + CDN with short TTL) |
| **Search** | Elasticsearch for user/ hashtag search |

## Deployment

```yaml
services:
  api-gateway: # REST + WebSocket gateway
  upload-service: # Image processing (thumbnails, filters)
  feed-service: # Hybrid feed generation
  graph-service: # Social graph (follow/following)
  story-service: # Ephemeral content
  
infrastructure:
  db-primary: PostgreSQL (user data, media metadata)
  db-graph: Cassandra (follows, likes, comments)
  cache: Redis Cluster (feeds, session, counters)
  storage: S3 + CloudFront CDN
  queue: SQS (fanout workers, image processing)
  search: Elasticsearch
```

## Interview Questions

1. How does Instagram generate the user feed?
2. How would you handle the "celebrity problem" with fanout?
3. How does Instagram optimize image upload and delivery?
4. Design Instagram Stories (ephemeral content)
5. How would you implement the "Explore" recommendations tab?
