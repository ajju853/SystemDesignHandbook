# Dropbox / Google Drive Clone

## Requirements

- File upload, download, sync across devices
- File versioning and history
- Sharing with permissions (view, edit, comment)
- Real-time collaboration (optional, like Google Docs)
- File organization (folders, stars, trash)
- 500M users, 10TB files/day uploads

## Capacity Estimation

```
Upload:           10TB/day ≈ 116 MB/s average, 500 MB/s peak
Storage:          3.65PB/year (10TB × 365)
User files/avg:   200 files per user → 500M × 200 = 100B files
Metadata:         100B files × 256B = 25TB
Versioning:       ~2x storage overhead → 7.3PB/year
Sync traffic:     500M users × 10 files/day × 1MB = 5PB/day
Deduplication:    30-50% reduction after dedup → ~2-3PB/year
```

## API Design

```
POST /files/upload/{path} → {file_id, name, size, version}
  Headers: Content-Type, Content-Length, Digest (SHA256)
  Body: binary file content

GET /files/{id}/download → binary
GET /files/{id}/metadata → {name, size, versions, shared_users}

POST /files/{id}/update → upload new version
GET /files/{id}/versions → [{version_id, size, modified_at}]

DELETE /files/{id} → soft delete (trash)
POST /trash/restore/{id}

POST /share/{file_id} → {emails[], permission}
GET /shared-with-me → [files]

GET /delta?cursor=... → changed files (sync protocol)

POST /folders → {name, parent_id}
GET /files/list?folder_id=...&cursor=...
```

## Database Design

```sql
-- Files and folders (unified tree structure)
CREATE TABLE file_entries (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    parent_id UUID REFERENCES file_entries(id),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(4) CHECK (type IN ('file', 'folder')),
    is_trashed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (user_id, parent_id, name),  -- no duplicates in same folder
    INDEX idx_user_trashed (user_id, is_trashed, parent_id)
);

-- File versions (immutable)
CREATE TABLE file_versions (
    id UUID PRIMARY KEY,
    file_id UUID NOT NULL REFERENCES file_entries(id),
    version_number INT NOT NULL,
    size BIGINT NOT NULL,
    content_hash VARCHAR(64) NOT NULL, -- SHA256 for dedup
    storage_path TEXT NOT NULL,
    mime_type VARCHAR(127),
    uploaded_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (file_id, version_number)
);

-- Content deduplication
CREATE TABLE content_blocks (
    hash VARCHAR(64) PRIMARY KEY,
    size INT NOT NULL,
    ref_count INT DEFAULT 1,
    storage_path TEXT NOT NULL
);

-- Sharing
CREATE TABLE shares (
    file_id UUID NOT NULL,
    shared_with UUID NOT NULL,  -- user_id
    permission VARCHAR(10) CHECK (permission IN ('view', 'edit', 'comment')),
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (file_id, shared_with)
);
```

## High-Level Design

```
┌──────────────────────────────────────────────────────────────┐
│                  File Sync Architecture                        │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Client ──► Sync Engine ──► API Gateway                       │
│    │                │               │                         │
│    │           ┌────┴────┐    ┌────┴────┐                    │
│    │           │ Delta   │    │ Metadata │                    │
│    │           │ Service │    │ Service  │                    │
│    │           └─────────┘    └────┬─────┘                    │
│    │                               │                          │
│  ┌─┴───────────────────────────────┴─┐                        │
│  │        Block-Level Storage         │                        │
│  │  ┌──────────┐  ┌──────────┐        │                        │
│  │  │Chunk     │  │Dedup     │        │                        │
│  │  │Service   │──►Service   │──► S3  │                        │
│  │  └──────────┘  └──────────┘        │                        │
│  └────────────────────────────────────┘                        │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## Low-Level Design: File Sync (Delta Protocol)

```
1. Client sends cursor (last sync token)
2. Server returns delta: files changed since cursor
3. Client compares with local state:
   a. Files changed on server → download
   b. Files changed locally → upload
   c. Files changed both → conflict resolution
4. File upload flow:
   a. Split file into 4MB blocks
   b. Compute SHA256 for each block
   c. Check each block hash against content_blocks table
   d. Upload only NEW blocks (dedup)
   e. Store block references → file_version record
5. New cursor returned to client
```

## Conflict Resolution Strategy

```
Conflict types:
1. Same file edited on two devices:
   → Create conflict copy ("filename (Conflicted Copy).ext")
2. File deleted on one device, edited on another:
   → Prefer edit, keep deleted in version history
3. Folder renamed vs. file added inside it:
   → Server-side ordering, retry on client

Implementation:
- Logical clocks (version vectors) per file
- Last-writer-wins for non-conflicting edits
- Branching for conflicts (like Dropbox)
```

## Scaling Strategy

| Component | Strategy |
|-----------|----------|
| **Metadata** | PostgreSQL sharded by user_id; read replicas |
| **Block storage** | S3/GCS; content-addressable (hash as key) |
| **Dedup** | content_blocks table; increment ref_count |
| **Delta sync** | Append-only event log per user (Kafka topic) |
| **Upload** | Resumable chunked upload (TUS protocol) |
| **Download** | CDN for popular files; direct S3 for long-tail |
| **Versioning** | Only store deltas between versions for large files |

## Deployment

```yaml
services:
  api-gateway: # REST + WebSocket
  meta-service: # File tree CRUD
  sync-service: # Delta protocol handler
  chunk-service: # Block storage + dedup
  upload-service: # Resumable upload handler
  
infrastructure:
  db: PostgreSQL (metadata, sharded)
  storage: S3 / GCS (block storage)
  cache: Redis (session, lock, temporary refs)
  queue: SQS (async dedup, thumbnail generation)
  cdn: CloudFront / Cloud CDN
```

## Interview Questions

1. How does Dropbox detect which files have changed and sync them?
2. How does block-level deduplication work?
3. How would you handle conflict resolution in a sync system?
4. Design the delta protocol for efficient client-server sync
5. How would you implement file versioning with storage efficiency?
