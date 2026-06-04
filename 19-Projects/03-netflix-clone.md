# Netflix Clone Backend

## Requirements

- Video upload and transcoding
- Adaptive bitrate streaming (HLS/DASH)
- User profiles and recommendations
- Watch history and resume
- CDN delivery
- 100M users, 10K concurrent streams
- 1000 hours of video uploaded/day

## Capacity Estimation

```
Uploads:     1000 hrs/day ≈ 500GB raw video/day
Transcoded:  1000 hrs × 5 qualities = ~2.5TB/day
Storage:     ~1PB/year (after compression)
Streaming:   10K concurrent × 5 Mbps = 50 Gbps
CDN egress:  ~50 Gbps peak, ~2PB/month
Metadata:    100M users, 50K titles → ~50GB
```

## API Design

```
POST /upload/init → {upload_url, video_id}
PUT {upload_url} (multipart, presigned S3 URL)
POST /upload/complete/{video_id}

GET /catalog → [{id, title, thumbnail, ...}]
GET /catalog/{id}/details → {title, description, cast, seasons}

GET /watch/{video_id}/manifest.m3u8 → HLS manifest
GET /watch/{video_id}/segment/{quality}/{seq}.ts → video segment

POST /progress/{video_id} → {position_seconds}
GET /progress → {video_id: position, ...}

GET /recommendations → [{video_id, score, reason}]
```

## Database Design

```sql
-- Video catalog
CREATE TABLE videos (
    id UUID PRIMARY KEY,
    title VARCHAR(255),
    description TEXT,
    duration_seconds INT,
    release_date DATE,
    maturity_rating VARCHAR(10),
    genre_ids UUID[],
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE video_qualities (
    id UUID PRIMARY KEY,
    video_id UUID REFERENCES videos(id),
    quality VARCHAR(10), -- 4K, 1080p, 720p, 480p, 360p
    codec VARCHAR(20),
    bitrate INT,
    s3_path TEXT,
    file_size BIGINT
);

CREATE TABLE user_progress (
    user_id UUID,
    video_id UUID,
    position_seconds INT,
    updated_at TIMESTAMP,
    PRIMARY KEY (user_id, video_id)
);

CREATE TABLE watch_history (
    user_id UUID,
    video_id UUID,
    watched_at TIMESTAMP,
    duration_watched INT,
    PRIMARY KEY (user_id, video_id, watched_at)
) PARTITION BY RANGE (watched_at);
```

## High-Level Design

```
┌───────────────────────────────────────────────────────────────┐
│                    Netflix Clone Architecture                   │
├───────────────────────────────────────────────────────────────┤
│                                                                │
│ Upload ──► Transcoder ──► S3/GCS ──► CDN ──► Client           │
│             │                    │               │              │
│         Encoding            Segment         Adaptive          │
│         Pipeline            Storage         Player            │
│         (FFmpeg,           (HLS/DASH                         │
│          parallel)          segments)                         │
│                                                                │
│ Client ──► API Gateway ──► Catalog ──► PostgreSQL              │
│                    ├──────► Progress ──► Cassandra              │
│                    ├──────► Recs ──► ML Model (Triton)          │
│                    └──────► Search ──► Elasticsearch             │
│                                                                │
└───────────────────────────────────────────────────────────────┘
```

## Low-Level Design: Transcoding Pipeline

```
1. Client uploads raw video to S3 (presigned URL)
2. S3 put event → SQS → Transcoder Service
3. Transcoder splits video into chunks (10s GOP)
4. Each chunk transcoded in parallel (FFmpeg Lambda)
5. Generate HLS manifest (.m3u8) + segments (.ts)
6. Upload manifests + segments to CDN origin
7. Update catalog with available qualities
8. Thumbnail generation (extracted key frames)
```

## Scaling Strategy

| Component | Scale |
|-----------|-------|
| **Transcoder** | Lambda/EC2 spot, parallel by chunk |
| **CDN** | CloudFront, Open Connect-like caching |
| **Catalog** | PostgreSQL read replicas + Redis cache |
| **Recommendations** | Batch offline ML + real-time scores |
| **Progress** | Cassandra (high write throughput) |
| **Search** | Elasticsearch cluster |

## Deployment

```yaml
services:
  api-gateway:
    image: netflix-gateway:latest
    scale: 5
  
  catalog-service:
    image: netflix-catalog:latest
    scale: 3
  
  progress-service:
    image: netflix-progress:latest
    scale: 3
  
  # Infra
  postgres: # RDS
  cassandra: # Multi-node cluster
  elasticsearch: # 3-node cluster
  redis: # Cluster mode
  kafka: # Event streaming
```

## Interview Questions

1. How does adaptive bitrate streaming work (HLS/DASH)?
2. How would you design the video transcoding pipeline?
3. How do you handle CDN cache for long-tail content?
4. How does Netflix's recommendation system work?
5. Design a system for resuming playback across devices
