# Design YouTube

## Requirements

- Video upload, transcoding, streaming
- 500+ hours uploaded per minute
- Global CDN streaming
- Search, recommendations, comments
- Live streaming support
- 2B monthly users

## Capacity Estimation

```
Uploads:      500 hrs/min → 720K hrs/day → ~2PB raw video/day
Transcoded:   720K hrs × 6 qualities = 4.3M hrs encoded/day
Storage:      ~2PB/day → 730PB/year (raw), ~150PB after compression
Views:        5B videos/day, 1B hrs watched/day
Bandwidth:    1B hrs × 720p avg 3Mbps = 3 Tbps peak
Comments:     50M/day
Search:       3B queries/day
```

## High-Level Design

```mermaid
graph TB
    subgraph Upload["Upload Pipeline"]
        Client[Client] --> UploadSvc[Upload Service]
        UploadSvc --> Queue[(Processing Queue - Pub/Sub)]
        Queue --> Transcoder[Transcoder Farm]
        Transcoder --> GCS[GCS Multi-Region]
        GCS --> CDN[Google Global Cache]
    end
    
    subgraph Serving["Serving"]
        Client2[Client] --> GFE[Google Frontend]
        GFE --> Watch[Watch Service]
        Watch --> CDN2[CDN]
        Watch --> Meta[(Metadata - Spanner)]
        GFE --> SearchSvc[Search Service]
        SearchSvc --> ES[(Search Index)]
    end
    
    subgraph Engagement["Engagement"]
        Watch --> Recs[Recommendation Engine]
        Recs --> DNN[Deep Neural Net]
        Watch --> Comment[Comment Service]
        Comment --> CommentDB[(Comment DB)]
    end
```

## Video Transcoding Pipeline

```mermaid
sequenceDiagram
    participant Upload as Upload Service
    participant Queue as Pub/Sub
    participant Transcoder as Transcoder Farm
    participant Storage as GCS
    
    Upload->>Queue: Upload complete event
    Queue->>Transcoder: New video notification
    
    Transcoder->>Transcoder: Split video into chunks (10s GOP)
    
    par Parallel Transcoding
        Transcoder->>Transcoder: Chunk 1 → 4K, 1080p, 720p, 480p, 360p
        Transcoder->>Transcoder: Chunk 2 → 4K, 1080p, 720p, 480p, 360p
        Transcoder->>Transcoder: Chunk N → 4K, 1080p, 720p, 480p, 360p
    end
    
    Transcoder->>Storage: Upload chunks + manifest
    Transcoder->>Transcoder: Generate thumbnails (key frames)
    Transcoder->>Storage: Upload thumbnails
    
    Transcoder->>Upload: Transcoding complete
```

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Storage** | GCS multi-region (not single region) | Closest to users for fast transcoding read |
| **CDN** | Google Global Cache (edge in ISP) | 50% of traffic is cacheable long-tail |
| **Transcoding** | Split video → parallel chunks → reassemble | Linear scaling with cluster size |
| **Metadata** | Cloud Spanner (globally distributed SQL) | Strong consistency for views, likes |
| **Recommendation** | Two-tower DNN (candidate gen + ranking) | Handles billions of videos, real-time |

## Interview Questions

1. How does YouTube's video transcoding pipeline work?
2. How does YouTube handle 500 hours of uploads per minute?
3. How does YouTube's recommendation system work?
4. Design YouTube search with autocomplete
5. How does YouTube Live streaming work differently from VOD?
