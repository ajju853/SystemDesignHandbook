# 19 — Projects

> Build real systems. Each project includes requirements, capacity estimation, API design, database design, high/low level design, scaling strategy, and deployment.

```mermaid
graph TB
    subgraph "Project Progression"
        B["Beginner<br/>URL Shortener"] --> I["Intermediate<br/>Chat, Instagram, Twitter,<br/>Food Delivery"]
        I --> A["Advanced<br/>Netflix, YouTube, Uber,<br/>Payment, Dropbox, Drive"]
    end
```

## Capstone Guide

| # | Project | Description |
|---|---------|-------------|
| 🌟 | [End-to-End Implementation Guide](12-end-to-end-implementation-guide.md) | Complete playbook: requirements → architecture → APIs → security → Docker → K8s → Terraform → CI/CD → observability → SRE — with E-Commerce Platform as running example |

## Design Projects

| # | Project | Difficulty | Tech Stack |
|---|---------|------------|------------|
| 1 | [URL Shortener](01-url-shortener.md) | Beginner | Node.js, Redis, PostgreSQL |
| 2 | [Chat System](02-chat-system.md) | Intermediate | WebSocket, Redis Pub/Sub |
| 3 | [Netflix Clone Backend](03-netflix-clone.md) | Advanced | Microservices, CDN |
| 4 | [YouTube Backend](04-youtube-backend.md) | Advanced | Video processing, CDN |
| 5 | [Uber Backend](05-uber-backend.md) | Advanced | Geospatial, real-time |
| 6 | [Payment Gateway](06-payment-gateway.md) | Advanced | Idempotency, transactions |
| 7 | [Instagram Backend](07-instagram-backend.md) | Intermediate | Feed, media storage |
| 8 | [Twitter Backend](08-twitter-backend.md) | Intermediate | Timeline, fanout |
| 9 | [Dropbox Clone](09-dropbox-clone.md) | Advanced | File sync, CRDTs |
| 10 | [Google Drive Clone](10-google-drive-clone.md) | Advanced | File storage, sharing, OT |
| 11 | [Food Delivery System](11-food-delivery-system.md) | Intermediate | Order matching, real-time |

## Full Stack & End-to-End Guides

| # | Guide | Description |
|---|-------|-------------|
| | [Java Full Stack Roadmap](19-java-full-stack-roadmap.md) | Complete end-to-end Java stack: Spring Boot, React, EKS, Kafka, Terraform, CI/CD — using E-Commerce OMS as example, with system design, data model, DevOps pipeline, cloud infra, and 20 interview questions |

---

Previous: [18 — Case Studies](../18-Case-Studies/README.md)
Next: [20 — Interview Prep](../20-Interview-Prep/README.md)
