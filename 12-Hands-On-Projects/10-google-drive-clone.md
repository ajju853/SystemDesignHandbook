# Google Drive Clone

## Requirements

- File upload, storage, and organization
- Google Docs-style real-time collaborative editing
- Spreadsheet with real-time cell updates
- File sharing with granular permissions
- Rich comment and suggestion system
- Offline support and conflict-free sync
- 1B users, 1T files stored

## Capacity Estimation

```
Files:            1T total, 10M new files/day
Docs created:     100M documents/day
Storage:          10M × 2MB avg = 20TB/day → 7.3PB/year
Real-time ops:    500K concurrent editors → 100K OT ops/sec
Spreadsheet cells: 10M sheets × 1000 cells = 10B cells
Revision history: 10 revisions/doc avg → ~20TB/day
Search index:     100M docs/day → Elasticsearch growth ~100GB/day
```

## API Design

```
// File Management
POST /drive/v1/files → upload file
GET /drive/v1/files/{id} → file metadata
PATCH /drive/v1/files/{id} → rename, move, star
DELETE /drive/v1/files/{id} → trash (soft delete)
GET /drive/v1/files?q=... → search files
GET /drive/v1/changes?pageToken=... → change log (sync)

// Collaborative Editing (WebSocket)
WS /doc/v1/{docId}
  → op: {type: insert|delete, pos, chars, client_id, revision}
  → ack: {revision, op_id}
  → broadcast: {op, author, revision}
  → cursor: {pos, client_id}

// Sharing
POST /drive/v1/files/{id}/permissions → {role, email}
GET /drive/v1/files/{id}/permissions → [{email, role}]
PATCH /drive/v1/files/{id}/permissions/{permId} → change role

// Comments
GET /drive/v1/files/{id}/comments → [{text, author, resolved}]
POST /drive/v1/files/{id}/comments → {text, anchor}
POST /drive/v1/comments/{id}/resolve
```

## Database Design

```sql
-- Files
CREATE TABLE files (
    id UUID PRIMARY KEY,
    owner_id UUID NOT NULL,
    parent_id UUID REFERENCES files(id),
    name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(127), -- application/vnd.google-apps.document, etc.
    size BIGINT,
    trashed BOOLEAN DEFAULT FALSE,
    starred BOOLEAN DEFAULT FALSE,
    version BIGINT DEFAULT 1,
    created_at TIMESTAMP,
    modified_at TIMESTAMP,
    UNIQUE (owner_id, parent_id, name)
);

-- Document operations (for OT/CRDT)
CREATE TABLE doc_operations (
    id BIGSERIAL,
    doc_id UUID NOT NULL,
    revision INT NOT NULL,
    client_id UUID NOT NULL,
    op_type VARCHAR(10), -- insert, delete, format
    op_data JSONB, -- {pos, chars, attributes}
    hash VARCHAR(64), -- checksum for consistency
    applied_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (doc_id, revision)
);

-- Revisions
CREATE TABLE doc_revisions (
    id UUID PRIMARY KEY,
    doc_id UUID NOT NULL,
    revision_start INT,
    revision_end INT,
    snapshot TEXT, -- compressed document state
    saved_at TIMESTAMP,
    INDEX idx_doc_revision (doc_id, revision_end DESC)
);

-- Spreadsheet cells (sparse storage)
CREATE TABLE sheet_cells (
    sheet_id UUID NOT NULL,
    row_num INT NOT NULL,
    col_num INT NOT NULL,
    value TEXT,
    formula TEXT,
    format JSONB, -- bold, italic, color, etc.
    version INT DEFAULT 1,
    PRIMARY KEY (sheet_id, row_num, col_num)
);

-- Permissions
CREATE TABLE permissions (
    file_id UUID NOT NULL,
    user_id UUID,
    email VARCHAR(255), -- for pending invites
    role VARCHAR(10) CHECK (role IN ('owner', 'writer', 'commenter', 'reader')),
    PRIMARY KEY (file_id, user_id)
);
```

## High-Level Design

```
                 ┌──────────────────────────────────────┐
                 │         Google Drive Architecture      │
                 ├──────────────────────────────────────┤
                 │                                       │
                 │  Client ──► API Gateway                │
                 │    │              │                    │
                 │  WebSocket    REST Endpoints          │
                 │  (collab)     (files, share)          │
                 │    │              │                    │
                 │  ┌─┴──────┐  ┌───┴───────┐            │
                 │  │ OT     │  │ Metadata  │            │
                 │  │ Engine │  │ Service   │            │
                 │  └───┬────┘  └───┬───────┘            │
                 │      │           │                     │
                 │  ┌───┴────┐  ┌───┴───────┐            │
                 │  │ Op Log │  │ PostgreSQL│            │
                 │  │(Kafka) │  │ (files)   │            │
                 │  └────────┘  └───────────┘            │
                 │                                       │
                 │  Storage Layer: GCS (multi-region)     │
                 │  Search: Elasticsearch                  │
                 │  Cache: Colossus/GFS (Google internal) │
                 └───────────────────────────────────────┘
```

## Low-Level Design: Operational Transformation

```
Two users edit the same document:

1. User A inserts "H" at position 0
   → op: {type: insert, pos: 0, chars: "H", rev: 1, client: A}
   → Server receives, applies, broadcasts

2. Simultaneously, User B inserts "I" at position 0
   → op: {type: insert, pos: 0, chars: "I", rev: 1, client: B}
   → Server receives AFTER A's op (server rev now 2)
   → Server transforms B's op against A's op:
     OT transform: insert "I" at pos 0 → insert "I" at pos 1
   → B's transformed op: {pos: 1, "I"}
   → Apply, broadcast

Result: "HI" instead of conflict

OT Transformation Function (simplified):
  transform(op1_insert, op2_insert):
    if op1.pos < op2.pos: op2.pos += len(op1.chars)
    elif op1.pos > op2.pos: op1.pos += len(op2.chars)
    else: tie-break by client_id
```

## Scaling Strategy

| Component | Strategy |
|-----------|----------|
| **OT Engine** | Partition by doc_id; in-memory state with Kafka log |
| **File metadata** | PostgreSQL sharded by owner_id hash |
| **Storage** | GCS/S3; content-addressable with dedup |
| **Real-time ops** | WebSocket to nearest region; Kafka for cross-region replication |
| **Spreadsheet** | Sparse storage for cells; lazy computation of formulas |
| **Search** | Elasticsearch; index file name, content, owner |
| **Revisions** | Snapshot every N ops; store diffs in between |
| **Sharing** | Permissions cached in Redis; TTL 5 min |

## Collaborative Editing Architecture

```
┌────────┐     WebSocket      ┌──────────┐     Kafka     ┌────────┐
│Client A│──────────────────► │  OT       │──────────────► │ Op Log │
└────────┘                    │  Service  │               └────────┘
                              │           │                    │
┌────────┐     WebSocket      │  (in      │              ┌─────┴─────┐
│Client B│──────────────────► │   memory  │              │ Revision  │
└────────┘                    │   state)  │              │ Snapshots │
                              └──────────┘              └───────────┘
- OT Service holds latest document state in memory
- All operations logged to Kafka (durable, replayable)
- Periodic snapshots taken every 100 ops for recovery
- Clients apply local ops optimistically, server confirms
```

## Deployment

```yaml
services:
  api-gateway: # Google Frontend-style proxy
  meta-service: # File and folder CRUD
  ot-service: # Operational Transformation engine (sharded by doc)
  sheet-service: # Spreadsheet computation engine
  share-service: # Permissions and sharing
  search-service: # Elasticsearch wrapper
  
infrastructure:
  db: Cloud Spanner (global consistency) or PostgreSQL sharded
  storage: GCS multi-region (nearline + coldline)
  cache: Redis / Colossus
  stream: Kafka (op log, 30-day retention)
  cdn: Cloud CDN (file downloads, thumbnails)
  compute: GKE (OT engine, metadata service)
```

## Interview Questions

1. How does Operational Transformation (OT) work for collaborative editing?
2. How would you design conflict resolution when two users edit the same file?
3. How does Google Drive handle file sync across multiple devices?
4. Design the spreadsheet formula recalculation engine
5. How would you implement Google Docs comment and suggestion system?
