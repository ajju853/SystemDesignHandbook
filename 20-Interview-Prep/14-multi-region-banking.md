# Design a Multi-Region Banking System

## Requirements

- Global payments and transfers across regions
- Strong consistency for balances
- Compliance with local regulations (GDPR, PSD2, SOX)
- 99.999% uptime (5 nines)
- Fraud detection in real-time
- Multi-currency support with FX
- Audit trail for every transaction

## Constraints

| Constraint | Implication |
|------------|-------------|
| **Regulatory** | Data must stay in region (EU → EU servers) |
| **Consistency** | No stale reads on balance — CP system |
| **Latency** | Cross-region transfers < 2s for local, < 10s for global |
| **Audit** | Every transaction immutable, append-only |
| **Disaster Recovery** | RPO = 0 (no data loss), RTO < 60s |

## Capacity Estimation

```
Accounts:       2B globally
Transactions:   500M/day (peak: 1000 TPS)
Cross-border:   50M/day
Balance reads:  2B/day
Audit log:      500M × 1KB = 500GB/day → 180TB/year
Fraud checks:   500M transactions × 2 queries = 1B reads/day
```

## High-Level Design

```mermaid
graph TB
    subgraph Region_A["Region A (US)"]
        API_A[API Gateway] --> TXN_A[Transaction Service]
        TXN_A --> Book_A[Accounting Ledger]
        Book_A --> Spanner_A[Cloud Spanner - Multi-Region]
        TXN_A --> Fraud_A[Fraud Detection]
        TXN_A --> Queue_A[Outbox Queue]
    end
    
    subgraph Region_B["Region B (EU)"]
        API_B[API Gateway] --> TXN_B[Transaction Service]
        TXN_B --> Book_B[Accounting Ledger]
        Book_B --> Spanner_B[Cloud Spanner - Multi-Region]
        TXN_B --> Fraud_B[Fraud Detection]
        TXN_B --> Queue_B[Outbox Queue]
    end
    
    Queue_A -.->|Cross-Region Replication| Queue_B
    Spanner_A -.->|Spanner Interleave| Spanner_B
    
    subgraph Global["Global Systems"]
        Settlement[Settlement Engine] --> FX[FX Service]
        Settlement --> Reconcile[Reconciliation Engine]
        Reporting[Reporting & Audit] --> DWH[(Data Warehouse)]
    end
```

## Transaction Flow (Cross-Region)

```mermaid
sequenceDiagram
    participant User as User (US)
    participant API as API Gateway
    participant TXN as Transaction Service
    participant Ledger as Accounting Ledger
    participant FX as FX Service
    participant Remote as EU Transaction Service
    participant Audit as Audit Log
    
    User->>API: Transfer $100 → €90 (EU account)
    API->>TXN: Validate balance (US account)
    TXN->>Ledger: BEGIN TRANSACTION
    
    par Local Debit
        Ledger->>Ledger: Debit $100 from US account
        Ledger->>Ledger: Credit $100 to suspense account
    end
    
    TXN->>FX: Get EUR/USD rate (locked for transaction)
    FX-->>TXN: Rate: 0.90, expires in 30s
    
    TXN->>Remote: Remote credit request<br/>(reference_id, €90, FX rate)
    
    alt Remote Success
        Remote-->>TXN: Credit confirmed
        TXN->>Ledger: Debit $100 from suspense, mark completed
        Ledger-->>TXN: Transaction committed
        TXN->>Audit: Append audit entry
        TXN-->>User: Success
    else Remote Failure
        Remote-->>TXN: Credit failed (rollback)
        TXN->>Ledger: Debit $100 from suspense, credit $100 to US
        TXN->>Ledger: Mark transaction FAILED
        Ledger-->>TXN: Rollback committed
        TXN-->>User: Failed, reason: recipient invalid
    end
```

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Global DB** | Cloud Spanner (TrueTime + Paxos) | Strong consistency across regions, 5 nines |
| **Local sharding** | By account_id hash | Even distribution, no hotspots |
| **Cross-region TXN** | Saga pattern (2-phase with compensating TXN) | No distributed lock, handles partial failure |
| **Audit** | Append-only event store | Immutable, satisfies SOX compliance |
| **Fraud** | Real-time ML (TensorFlow Serving) + rule engine | < 50ms per check |
| **Idempotency** | idempotency_key = SHA256(user_id, amount, timestamp, nonce) | Prevents double-spend |

## Disaster Recovery Strategy

```
Active-Passive per region (Spanner multi-region):
- Each Region has: Primary + 2 Witnesses in nearby zones
- Spanner provides: RPO=0, RTO<60s automatically

Cross-Region DR:
- Region A (US-East) = Primary for US accounts
- Region B (EU-West) = Primary for EU accounts
- Each region maintains a standby in alternate geography

Failover:
1. Spanner auto-failover (Paxos-based, < 60s)
2. Transaction Service is stateless (just reroute traffic)
3. Queued outbox messages replay after failover
```

## Interview Questions

1. How do you handle cross-region money transfers with strong consistency?
2. How does the Saga pattern work for distributed transactions in banking?
3. How do you achieve 5 nines uptime across regions?
4. Design the fraud detection system for real-time transactions
5. How do you handle regulatory compliance (data residency, audit trails)?
