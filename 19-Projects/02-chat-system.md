# Chat System

## Requirements

- 1-on-1 and group messaging
- Real-time delivery (WebSocket)
- Message persistence (history)
- Read receipts, typing indicators
- Media sharing (images, files)
- Online/offline presence
- 500M users, 100B messages/day

## Capacity Estimation

```
Messages:   100B/day ≈ 1.2M writes/sec
Reads:      500B reads/day ≈ 5.8M reads/sec
Storage:    100B msgs × 1KB = 100TB/day → 36.5PB/year
Media:      10B media/day × 200KB = 2PB/day
Bandwidth:  ~1.2M × 1KB + media = 100+ Gbps
```

## API Design

```
WebSocket /ws
  → connect(token)
  → send_message(chat_id, text, media_ids)
  → mark_read(chat_id, message_id)
  → typing(chat_id, is_typing)
  ← message(chat_id, sender, text, timestamp)
  ← read_receipt(chat_id, message_id, user_id)
  ← presence(user_id, status)

REST
  GET /chats → list user's chats
  POST /chats → create chat (users[])
  GET /chats/{id}/messages?cursor=... → paginated history
  POST /media → upload file (presigned URL)
```

## Database Design

```sql
-- Chats
CREATE TABLE chats (
    id UUID PRIMARY KEY,
    type VARCHAR(10) CHECK (type IN ('direct', 'group')),
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE chat_members (
    chat_id UUID REFERENCES chats(id),
    user_id UUID REFERENCES users(id),
    joined_at TIMESTAMP DEFAULT NOW(),
    last_read_message_id BIGINT,
    PRIMARY KEY (chat_id, user_id)
);

-- Messages (partitioned by date)
CREATE TABLE messages (
    id BIGSERIAL,
    chat_id UUID NOT NULL,
    sender_id UUID NOT NULL,
    text TEXT,
    media_ids UUID[],
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (chat_id, created_at, id)
) PARTITION BY RANGE (created_at);

-- Indexes for last-message-per-chat query
CREATE INDEX idx_messages_chat_created 
ON messages (chat_id, created_at DESC);
```

## High-Level Design

```
┌──────────────────────────────────────────────────────────┐
│                   Chat Architecture                       │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  Client ──WebSocket──► Connection Gateway                 │
│                           │                               │
│                    ┌──────┴──────┐                        │
│                    │  Chat       │                        │
│                    │  Service    │                        │
│                    └──────┬──────┘                        │
│                           │                               │
│              ┌────────────┼────────────┐                  │
│              │            │            │                  │
│         ┌────┴────┐ ┌────┴────┐ ┌────┴────┐             │
│         │ Kafka   │ │ Redis   │ │ Postgres│             │
│         │(events) │ │(presence│ │(history)│             │
│         │         │ │,sessions│ │         │             │
│         └─────────┘ └─────────┘ └─────────┘             │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

## Low-Level Design: Message Flow

```
1. Alice sends message → WebSocket to Connection Gateway
2. Gateway publishes to Kafka topic "chat.messages"
3. Chat Service consumes, stores in PostgreSQL
4. Chat Service publishes to Kafka topic "chat.deliver"
5. Delivery Service fans out:
   - If recipient connected: push via WebSocket
   - If not: store offline notification
6. Recipient receives message (or gets on reconnect)
```

## Scaling Strategy

| Component | Strategy |
|-----------|----------|
| **WebSocket Gateway** | Stateless (session in Redis), auto-scale by connections |
| **Chat Service** | Partitioned by chat_id (consistent hashing) |
| **Messages DB** | Range-partitioned by date, archive old partitions |
| **Redis** | Cluster mode for presence + session data |
| **Kafka** | Partition by chat_id for ordering |
| **Media** | CDN + S3 with presigned URLs |

## Deployment

```yaml
# docker-compose.yml skeleton
services:
  gateway:
    image: chat-gateway:latest
    scale: 20
    ports: ["8080-8090:8080"]
    environment:
      REDIS_URL: redis://redis-cluster:6379
      KAFKA_BROKERS: kafka:9092
  
  chat-service:
    image: chat-service:latest
    scale: 10
    environment:
      DB_URL: postgresql://postgres/chat
      KAFKA_BROKERS: kafka:9092
  
  redis-cluster:
    image: redis:7
  
  kafka:
    image: confluentinc/cp-kafka:latest
  
  postgres:
    image: postgres:16
```

## Interview Questions

1. How do you guarantee message ordering in a chat system?
2. How do you handle offline messages and delivery?
3. How do you scale WebSocket connections horizontally?
4. How do you detect and handle duplicate message delivery?
5. Design end-to-end encryption for the chat system
