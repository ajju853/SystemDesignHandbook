# System Design Mastery

> From zero to staff engineer — a complete Cloud + System Design + DevOps + Architecture learning operating system.

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

## The Learning Path

```
                       ┌─────────────────────────────────────┐
                       │   21-Staff Engineer                 │
                       │   Tradeoffs, RFCs, Chaos Engineering │
                       └─────────────────────────────────────┘
                                       │
                 ┌─────────────────────┼─────────────────────┐
                 ▼                     ▼                     ▼
     ┌──────────────────────┐ ┌──────────────────┐ ┌──────────────────┐
     │ 20-Interview Prep    │ │ 19-Projects       │ │ 18-Case Studies  │
     │ 17 Interview Problems│ │ 11 Hands-On Labs  │ │ Architectures +  │
     │ + Interactive Tools  │ │ + Cloud Deployments│ │ Incidents         │
     └──────────────────────┘ └──────────────────┘ └──────────────────┘
                                       │
        ┌──────┬──────┬──────┬──────┬──┴──┬──────┬──────┬──────┬──────┐
        ▼      ▼      ▼      ▼      ▼      ▼      ▼      ▼      ▼      ▼
    ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐
    │ 10 │ │ 11 │ │ 12 │ │ 13 │ │ 14 │ │ 15 │ │ 16 │ │ 17 │ │ 08 │ │ 09 │
    │AWS │ │Az. │ │GCP │ │TF  │ │Dev │ │SRE │ │Sec.│ │Obs.│ │Dkr │ │K8s │
    └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    ▼                  ▼                  ▼
          ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
          │ 05-System Design │ │ 06-Dist. Systems │ │ 07-Microservices │
          │ Caching, Queues, │ │ Consensus, Raft, │ │ DDD, Circuit     │
          │ Patterns         │ │ ZooKeeper, Lock  │ │ Breaker, Sagas   │
          └──────────────────┘ └──────────────────┘ └──────────────────┘
                                       │
        ┌──────────────────────────────┼──────────────────────────────┐
        ▼                              ▼                              ▼
┌──────────────────┐          ┌──────────────────┐          ┌──────────────────┐
│ 01-CS Fund.      │          │ 02-Networking     │          │ 04-Databases     │
│ CAP, Scalability,│          │ HTTP, TCP/IP, DNS,│          │ SQL, NoSQL,      │
│ Consistency      │          │ CDN, WebSocket    │          │ Sharding, ACID   │
└──────────────────┘          └──────────────────┘          └──────────────────┘
        │                              │                              │
        └──────────────────────────────┼──────────────────────────────┘
                                       ▼
                               ┌──────────────────┐
                               │ 03-Linux          │
                               │ Processes, Memory,│
                               │ Networking, Shell │
                               └──────────────────┘
```

## Module Index

| # | Module | Topics | Files |
|---|--------|--------|-------|
| 01 | [Computer Science Fundamentals](01-Computer-Science-Fundamentals/) | CAP, Scalability, H/V Scaling, Latency, Throughput, Consistency | 15 |
| 02 | [Networking](02-Networking/) | OSI, TCP, UDP, HTTP, HTTPS, REST, GraphQL, gRPC, DNS, CDN | 15 |
| 03 | [Linux](03-Linux/) | Processes, Memory, FS, Networking, Shell Scripting, Performance | 10 |
| 04 | [Databases](04-Databases/) | PostgreSQL, MySQL, MongoDB, Cassandra, DynamoDB, Redis, Elasticsearch, Indexing | 16 |
| 05 | [System Design](05-System-Design/) | Caching Patterns, Message Queues, Kafka, RabbitMQ, SQS, Pulsar | 19 |
| 06 | [Distributed Systems](06-Distributed-Systems/) | Consensus, Paxos, Raft, Leader Election, ZooKeeper, etcd | 9 |
| 07 | [Microservices](07-Microservices/) | DDD, Service Mesh, API Gateway, Circuit Breaker, Sagas, CQRS | 11 |
| 08 | [Docker](08-Docker/) | Containers, Images, Dockerfile, Compose, Networking, Volumes | 2 |
| 09 | [Kubernetes](09-Kubernetes/) | Pods, Deployments, Services, EKS/GKE/AKS Comparison | 3 |
| 10 | [AWS](10-AWS/) | 28 services: EC2, Lambda, S3, VPC, RDS, DynamoDB, EKS, IAM, etc. | 33 |
| 11 | [Azure](11-Azure/) | 18 services: VMs, Functions, AKS, Cosmos DB, Blob, Entra ID | 20 |
| 12 | [GCP](12-GCP/) | 17 services: GKE, Compute Engine, BigQuery, Spanner, Cloud Run | 21 |
| 13 | [Terraform](13-Terraform/) | IaC, Providers, Modules, State, AWS Provisioning, Best Practices | 10 |
| 14 | [DevOps](14-DevOps/) | Git Workflows, GitHub Actions, Jenkins, ArgoCD, Helm, Ansible, CI/CD | 11 |
| 15 | [SRE](15-SRE/) | SLO/SLI/Error Budgets, Incident Mgmt, Postmortems, Capacity Planning | 10 |
| 16 | [Security](16-Security/) | Auth, JWT, OAuth, RBAC, ABAC, Encryption, WAF, DDoS | 13 |
| 17 | [Observability](17-Observability/) | Logging, Monitoring, Tracing, Metrics, Prometheus, Grafana, ELK | 11 |
| 18 | [Case Studies](18-Case-Studies/) | Netflix, YouTube, Uber, WhatsApp, Instagram, Twitter, Spotify + 7 Production Incidents | 18 |
| 19 | [Projects](19-Projects/) | URL Shortener, Chat System, Netflix Clone, Uber, Payment Gateway, + more | 12 |
| 20 | [Interview Prep](20-Interview-Prep/) | 17 System Design Interview Solutions + Interactive Quiz/Tools | 21 |
| 21 | [Staff Engineer](21-Staff-Engineer/) | Tradeoffs, RFC Writing, Cost Optimization, Multi-Region, DR | 10 |

## Multi-Cloud Mapping

| Category | AWS | Azure | GCP |
|----------|-----|-------|-----|
| Compute | EC2 | VMs | Compute Engine |
| Serverless | Lambda | Functions | Cloud Functions |
| Containers | EKS | AKS | GKE |
| Object Storage | S3 | Blob Storage | Cloud Storage |
| Relational DB | RDS | Azure SQL | Cloud SQL |
| NoSQL | DynamoDB | Cosmos DB | Bigtable/Firestore |
| Warehouse | Redshift | Synapse | BigQuery |
| Queue | SQS | Service Bus | Pub/Sub |
| Monitoring | CloudWatch | Azure Monitor | Operations Suite |

[Full Multi-Cloud Mapping →](12-GCP/19-multi-cloud-mapping.md)

## Certifications

| Cloud | Foundational | Associate | Professional |
|-------|-------------|-----------|-------------|
| **AWS** | Cloud Practitioner | Solutions Architect Associate | Solutions Architect Professional |
| **Azure** | AZ-900 | AZ-104 Administrator | AZ-305 Architect Expert |
| **GCP** | Cloud Digital Leader | Associate Cloud Engineer | Professional Cloud Architect |

- [AWS Certifications](10-AWS/32-certifications.md)
- [Azure Certifications](11-Azure/19-certifications.md)
- [GCP Certifications](12-GCP/20-certifications.md)

## How to Use This Repository

```
# Clone
git clone https://github.com/ajju853/SystemDesignHandbook.git

# Start from the beginning
01-Computer-Science-Fundamentals/01-what-is-system-design.md

# Or jump to your level
# Beginner: Modules 01-05
# Intermediate: Modules 06-12
# Advanced: Modules 13-17
# Staff Engineer: Module 21
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT
