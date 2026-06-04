# Amazon Architecture

## Overview
Amazon's architecture is legendary for its "two-pizza team" model, API-first design, and cell-based architecture.

```mermaid
graph LR
    Client[User] --> CF[CloudFront CDN]
    CF --> ELB[Elastic Load Balancer]
    ELB --> App[Application Tier]
    subgraph Cell[Cell-Based Architecture]
        Product[Product Service]
        Order[Order Service]
        Payment[Payment Service]
        Cart[Cart Service]
    end
    App --> Cell
    Product --> Dyn[(DynamoDB)]
    Order --> Dyn
    Payment --> Aurora[(Aurora)]
    Cart --> Dyn
    subgraph Team[Two-Pizza Teams]
        T1[Team: Catalog]
        T2[Team: Checkout]
        T3[Team: Payments]
    end
    Product -.->|owned by| T1
    Order -.->|owned by| T2
    Payment -.->|owned by| T3
```

## Key Principles

| Principle | Impact |
|-----------|--------|
| **Two-pizza teams** | Small (<8), autonomous teams |
| **API-first** | Every team exposes APIs, no direct DB access |
| **Cell-based** | Isolated failure domains |
| **BUILDER culture** | Engineers own full lifecycle |
| **PR/FAQ** | Press release + FAQ for new features |

## Architecture

```
Client ──► CloudFront ──► ELB ──► Application Tier
                                        │
                                   ┌────┴────┐
                                   │ Service  │
                                   │ Tier     │
                                   │ ┌──────┐ │
                                   │ │Product│ │
                                   │ │Service│ │
                                   │ ├──────┤ │
                                   │ │Order  │ │
                                   │ │Service│ │
                                   │ ├──────┤ │
                                   │ │Payment│ │
                                   │ │Service│ │
                                   │ └──────┘ │
                                   └────┬────┘
                                        │
                                   ┌────┴────┐
                                   │ Database │
                                   │ (DynamoDB│
                                   │  Aurora) │
                                   └─────────┘
```

## Interview Questions
1. How did Amazon's "two-pizza team" model influence its architecture?
2. How does Amazon's cell-based architecture improve fault isolation?
3. How does Amazon handle product catalog at massive scale?
4. What is the PR/FAQ process and why does it work?
5. Design a simplified Amazon e-commerce system
