# Spotify Architecture

## Overview
Spotify serves 500M+ users with a backend composed of 1200+ microservices, emphasizing squad autonomy and event-driven communication.

```mermaid
graph LR
    Client[Client App<br/>Most logic on client] --> Apollo[Apollo API Gateway]
    Apollo --> Playlist[Playlist Service<br/>CRDT-based offline sync]
    Apollo --> Discovery[Discovery Service<br/>ML Recommendations]
    Apollo --> Social[Social Service]
    Apollo --> Search[Search Service]
    Apollo --> Ads[Ads Service]
    Apollo --> Podcast[Podcast Service<br/>Anchor/Megaphone]
    Playlist --> DB[(Cassandra + PostgreSQL)]
    Discovery --> DB
    Social --> DB
    subgraph EventBus[Event Bus]
        Kafka[Apache Kafka<br/>Pub/Sub]
    end
    Playlist -.->|events| Kafka
    Discovery -.->|events| Kafka
```

## Architecture

```
Client ──► Apollo (API Gateway)
              │
         ┌────┴────┐
         │ Microservices │
         │ Playlist,      │
         │ Discovery,      │
         │ Social,         │
         │ Ads, Search    │
         └────┬────┘
              │
         ┌────┴────┐
         │ Storage  │
         │ Cassandra + │
         │ PostgreSQL  │
         └─────────┘
```

## Key Features

| Feature | Implementation |
|---------|---------------|
| **Music Discovery** | ML-based recommendations (collaborative filtering) |
| **Playlist Sync** | CRDT-based offline sync |
| **Podcast Hosting** | Anchor, Megaphone infrastructure |
| **Client-serving** | Most logic on client, backend for data |
| **Event-driven** | Apache Kafka, Pub/Sub |

## Interview Questions
1. How does Spotify's recommendation engine work?
2. How does Spotify handle offline music playback and sync?
3. How does Spotify's squad model influence architecture?
4. How does Spotify handle podcast ingestion at scale?
5. Design a simplified Spotify music streaming backend
