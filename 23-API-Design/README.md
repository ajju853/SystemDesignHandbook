# 23 — API Design

> Master the art and science of designing, building, documenting, securing, and evolving APIs at scale.

## Module Overview

API Design is the backbone of modern distributed systems. This module covers the full spectrum — from RESTful design principles and OpenAPI documentation to GraphQL, gRPC, real-time protocols, security, gateway patterns, testing, and webhooks. Each file dives deep into architecture, hands-on examples, best practices, and real-world usage.

```mermaid
mindmap
  root((API Design))
    REST APIs
      01-rest-api-design
      Resource modeling
      HTTP methods & status
      HATEOAS / pagination
      Error handling standards
    Specification
      02-openapi-spec
      OpenAPI 3.1 YAML/JSON
      Code generation tools
      Swagger UI / Redoc
      Spectral validation
    GraphQL
      03-graphql-deep-dive
      Schema / resolvers
      N+1 & DataLoader
      Federation / security
      Apollo / persisted queries
    gRPC
      04-grpc-deep-dive
      Protocol buffers
      4 streaming modes
      Interceptors / deadlines
      grpc-gateway
    Versioning
      05-api-versioning
      URI / header / query
      Backward compatibility
      Breaking change detection
      Sunset policies
    Security
      06-api-security
      OAuth2 / OIDC / JWT
      Rate limiting / CORS
      OWASP API Top 10
      API firewalls
    Gateways
      07-api-gateway-patterns
      BFF / aggregation / routing
      Circuit breaking
      Service mesh comparison
      Kong / Apigee / AWS
    Real-time
      08-websocket-sse
      WebSocket protocol
      Server-Sent Events
      Scaling strategies
      Reconnection patterns
    Webhooks
      09-webhook-patterns
      Retry / idempotency
      Payload signing
      Dead letter queues
      Consumer verification
    Testing
      10-api-testing
      Contract testing / Pact
      Fuzzing / property-based
      Performance testing
      Postman / monitoring
```

```mermaid
graph LR
    subgraph "Foundation"
        A[01-rest-api-design] --> B[02-openapi-spec]
    end
    subgraph "Protocols"
        C[03-graphql-deep-dive]
        D[04-grpc-deep-dive]
    end
    subgraph "Cross-Cutting"
        E[05-api-versioning]
        F[06-api-security]
    end
    subgraph "Infrastructure"
        G[07-api-gateway-patterns]
    end
    subgraph "Real-Time & Events"
        H[08-websocket-sse]
        I[09-webhook-patterns]
    end
    subgraph "Quality"
        J[10-api-testing]
    end
    A --> C
    A --> D
    B --> C
    B --> D
    C --> E
    D --> E
    A --> F
    C --> F
    D --> F
    E --> G
    F --> G
    C --> H
    A --> I
    G --> I
    G --> H
    A --> J
    B --> J
    F --> J
    style A fill:#4a90d9,color:#fff
    style B fill:#4a90d9,color:#fff
    style C fill:#7b68ee,color:#fff
    style D fill:#7b68ee,color:#fff
    style E fill:#e67e22,color:#fff
    style F fill:#e74c3c,color:#fff
    style G fill:#2ecc71,color:#fff
    style H fill:#1abc9c,color:#fff
    style I fill:#1abc9c,color:#fff
    style J fill:#f39c12,color:#fff
```

## Learning Path

1. **Start with REST** (01) — it remains the most widely adopted API style and establishes vocabulary (resources, methods, status codes).
2. **Specify with OpenAPI** (02) — learn how to describe REST APIs formally; essential for documentation, code generation, and validation.
3. **Explore Modern Protocols** (03, 04) — GraphQL and gRPC solve different problems; understand when each beats REST.
4. **Manage Change** (05) — API versioning is inevitable; learn strategies that minimize consumer pain.
5. **Secure Everything** (06) — OAuth2, JWT, and OWASP Top 10 are non-negotiable for production APIs.
6. **Scale with Gateways** (07) — API gateways and service meshes handle cross-cutting concerns at the infrastructure layer.
7. **Go Real-Time** (08) — WebSockets and SSE for low-latency, event-driven communication.
8. **Automate with Webhooks** (09) — event-driven callback patterns for async integrations.
9. **Verify Quality** (10) — contract testing, fuzzing, and performance testing ensure API reliability.

---
Previous: [22 — AI/ML System Design](../22-AI-ML-System-Design/README.md)
Next: [24 — Testing & Quality Engineering](../24-Testing-Quality-Engineering/README.md)
