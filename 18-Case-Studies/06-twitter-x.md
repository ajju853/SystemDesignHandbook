# Twitter/X Architecture

## Overview
Twitter handles 500M+ tweets/day, 6K+ tweets/second peak, with a fanout-based timeline delivery system.

```mermaid
graph LR
    User[User] --> Write[Write API]
    Write --> TweetSvc[Tweet Service]
    TweetSvc --> Fanout[Fanout Engine]
    Fanout --> Active[Active Users<br/>Redis Timeline Cache]
    Fanout --> Inactive[Inactive Users<br/>MySQL Timeline]
    Fanout --> Celeb[&gt;1M Followers<br/>Pull-based Fanout]
    Active --> Read[Read API]
    Inactive --> Read
    Read --> Client[Client Timeline]
    TweetSvc --> Snowflake[Snowflake ID Generator<br/>64-bit unique IDs]
```

## Architecture

```
Tweet ──► Write API ──► Tweet Service ──► Timeline Service
                                      │
                                 Fanout Engine
                                 │         │
                            ┌─────┘         └─────┐
                            ▼                     ▼
                     Active Users'         Inactive Users'
                     Timeline (Redis)      Timeline (MySQL)
                            │                     │
                            └──────────┬──────────┘
                                       ▼
                                  Read API
                                       │
                                       ▼
                                    Client
```

## Key Lessons

| Lesson | Detail |
|--------|--------|
| **Fanout-on-write** | Write tweet → push to followers' timelines |
| **Hybrid fanout** | Celebrities don't fanout (pull instead) |
| **Redis clusters** | Timeline cache for active users |
| **Snowflake IDs** | 64-bit unique ID generator |
| **Manhattan** | Distributed key-value store (replacing Cassandra) |

## Interview Questions
1. How does Twitter's fanout service work?
2. How does Twitter handle celebrity accounts (millions of followers)?
3. How does Twitter's trending topics algorithm work?
4. What's the Snowflake ID and why was it needed?
5. Design a simplified Twitter timeline system
