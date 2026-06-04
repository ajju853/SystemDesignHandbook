# Testing Strategies for Microservices

## What is it?

Testing microservices is fundamentally harder than testing monoliths because services have network boundaries, independent deployments, and multiple languages/databases. A layered testing strategy with the right automation pyramid is essential.

## Test Pyramid for Microservices

```mermaid
flowchart TB
    subgraph Pyramid["Microservices Test Pyramid"]
        E2E["🔼 E2E Tests<br/>Few — critical paths only"]
        CT["Contract Tests<br/>(Pact / Spring Cloud Contract)"]
        INT["Integration Tests<br/>External dependencies (DB, MQ, API)"]
        COMP["Component Tests<br/>Single service in isolation"]
        UNIT["Unit Tests<br/>Business logic, fast"]
    end
```

| Layer | Velocity | Scope | Reliability | Cost |
|-------|----------|-------|-------------|------|
| Unit | Fast (ms) | Single class/function | High | Low |
| Component | Fast (s) | Single service | High | Low |
| Integration | Slow (min) | Service + dependencies | Medium | Medium |
| Contract | Medium | Service API compatibility | High | Low |
| E2E | Very Slow (hrs) | Multiple services | Low (flaky) | Very High |

## Contract Testing (Consumer-Driven Contracts)

Contract testing ensures that a service provider meets the expectations of its consumers without running the full system.

```mermaid
sequenceDiagram
    participant CD as Consumer Dev
    participant CR as Consumer
    participant PR as Provider
    participant PD as Provider Dev

    CD->>CR: Write consumer test
    CR->>CR: Define expected interactions
    CR->>CR: Generate Pact file
    CR->>PR: Publish contract (Pact file)

    PR->>PD: Verify against provider
    PD->>PR: Provider validates contract
    PR-->>PD: Pass/Fail

    Note over CR,PR: CI pipeline: consumer publishes contract → provider validates
```

### Pact

[Pact](https://pact.io) is the most popular contract testing framework:

- **Consumer** writes a test that defines expected requests and responses
- Pact generates a **contract file** (JSON)
- **Provider** replays the contract against its actual implementation
- If all contracts pass → services are compatible

**Benefits**: Catch breaking API changes before deployment, no need for full environment, parallel development.

## Integration Testing

Test each service with its real dependencies (DB, message queue, cache) but stub external services.

```mermaid
flowchart LR
    SVC["Order Service"] --- DB[("Test DB<br/>Testcontainers")]
    SVC --- MQ[("Test MQ<br/>in-memory")]
    SVC -.->|"HTTP stub"| PS["Payment Service<br/>(WireMock)"]

    subgraph Real["Real Infrastructure (Testcontainers)"]
        DB
        MQ
    end

    subgraph Stub["External Services (WireMock)"]
        PS
    end
```

**Tools**: Testcontainers (Java), Docker Compose, LocalStack (AWS services), WireMock

## End-to-End Testing

Run against a full deployment in a staging environment. Focus on critical user journeys:

- User registration → login → place order → payment → confirmation
- Service must be fully deployed (Docker Compose, k8s, or dedicated env)
- Prone to flakiness — retry failed tests and investigate patterns

## Deployment Strategies

### Blue-Green Deployment

```mermaid
flowchart LR
    LB["Load Balancer"] -->|"100% traffic"| BLUE["Blue (v1)"]
    LB -.->|"0% traffic"| GREEN["Green (v2)"]

    BLUE ---|"Active"| DB[(Database)]

    subgraph Switch["Switch"]
        SW["Route all traffic to Green"]
    end

    GREEN ---|"After switch"| DB
```

- **Blue**: current version
- **Green**: new version (deployed in parallel)
- Switch traffic instantly; rollback is one switch away

### Canary Deployment

```mermaid
flowchart LR
    LB["Load Balancer"] -->|"90%"| STABLE["Stable (v1)"]
    LB -->|"10%"| CANARY["Canary (v2)"]

    CANARY --> MON["Monitor<br/>Error Rate / Latency"]

    MON -->|"No issues → 25% → 50% → 100%"| PROMOTE["Promote v2"]
    MON -->|"Errors ↑ → Rollback"| ROLLBACK["Rollback to v1"]
```

Gradually shift traffic to the new version while monitoring metrics. If error rate or latency increases → rollback.

## Best Practices

1. **Invest heavily in unit tests** (70% of effort) — they're fast and cheap
2. **Use contract tests** (Pact) before E2E — catch API mismatches early
3. **Test idempotency** — same request twice produces the same result
4. **Test resilience** — circuit breakers, timeouts, retries (chaos engineering)
5. **Use Testcontainers** for integration tests — real databases in ephemeral containers
6. **Keep E2E tests minimal** (< 5% of total) — test only critical user journeys
7. **Run tests in CI pipeline per service** — don't wait for full system
8. **Implement consumer-driven contracts** — providers know what consumers expect
9. **Canary releases in production** — validate with real traffic before full rollout

## Interview Questions

1. How does the test pyramid differ for microservices vs monoliths?
2. What is consumer-driven contract testing and how does Pact work?
3. Compare blue-green deployment vs canary deployment.
4. How do you test a saga's compensating transactions?
5. How do you avoid flaky E2E tests?
6. How would you test a circuit breaker in integration tests?

## Cross-Links

- [08-Docker/Testing](../08-Docker/README.md)
- [09-Kubernetes/Rolling-Updates](../09-Kubernetes/README.md)
- [14-DevOps/CI-CD](../14-DevOps/README.md)
- [06-circuit-breaker.md](06-circuit-breaker.md)
