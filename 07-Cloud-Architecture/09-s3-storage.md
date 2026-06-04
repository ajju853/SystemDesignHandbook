# S3 & Storage

## Definition
Amazon S3 (Simple Storage Service) is an object storage service offering industry-leading scalability, data availability, security, and performance. It's designed for 99.999999999% durability (11 nines).

## Key Features

- **11 nines durability** — Automatically replicates across >= 3 AZs
- **Unlimited storage** — Objects from 0 bytes to 5 TB
- **Event notifications** — S3 → Lambda, SQS, SNS, EventBridge
- **Versioning** — Protect against accidental deletes
- **Lifecycle policies** — Auto-tier between storage classes
- **Cross-region replication** — Async replication to another region
- **Access control** — Bucket policies, IAM, ACLs, presigned URLs
- **Static website hosting** — Serve HTML/JS/CSS directly

## Storage Classes

| Class | Durability | Availability | Min Storage | Retrieval | Relative Cost |
|-------|------------|--------------|-------------|-----------|---------------|
| **S3 Standard** | 11 nines | 99.99% | None | Instant | 100% (baseline) |
| **Intelligent-Tiering** | 11 nines | 99.9% | 30 days | Instant | Auto-optimized |
| **Standard-IA** | 11 nines | 99.9% | 30 days | Instant | ~60% |
| **One Zone-IA** | 11 nines | 99.5% | 30 days | Instant | ~40% |
| **Glacier Instant** | 11 nines | 99.9% | 90 days | milliseconds | ~30% |
| **Glacier Flexible** | 11 nines | 99.99% | 90 days | 1-5 min | ~10% |
| **Glacier Deep Archive** | 11 nines | 99.99% | 180 days | 12-48 hrs | ~4% |

## How S3 Achieves 11 Nines Durability

```
Object stored in S3:
  1. Object is split into chunks
  2. Each chunk is replicated across >= 3 AZs in the region
  3. Parity bits are computed for reconstruction
  4. Background verification: integrity checked with CRC (every 12 months)
  5. If corruption detected → auto-repair from redundant copy
  6. Result: Expected loss = 1 object per 10,000,000,000,000 objects per year

Compare:
  - Enterprise HDD: 10^14 bit error rate → ~1 error per 12 TB read
  - S3: 10^15 error rate per bit read → ~1 error per 125 TB read
  - S3 durability: 99.999999999% → lose 1 object per 100B objects/year
```

## S3 vs EBS vs EFS

| Feature | S3 (Object) | EBS (Block) | EFS (File - NFS) |
|---------|-------------|-------------|------------------|
| **Access** | HTTP/REST | Attached to single EC2 | NFS mounted by many EC2 |
| **Use case** | Static assets, backup, data lakes | OS disk, databases | Shared file system |
| **Performance** | Up to 100 Gbps | Up to 260K IOPS (io2) | Up to 10 GB/s |
| **Scaling** | Unlimited | 16 TB max per volume | Unlimited (auto-scaling) |
| **Persistence** | Independent of EC2 | Lives after EC2 stop | Persistent |
| **Cost** | ~$0.023/GB | ~$0.08/GB (gp3) | ~$0.30/GB |

## Interview Questions

1. How does S3 achieve 11 nines durability?
2. Compare S3, EBS, and EFS — when would you use each?
3. How do you secure data in S3 (encryption at rest/in transit)?
4. Design a data archival strategy using S3 lifecycle policies
5. How would you serve a large file (10GB) from S3 efficiently?
6. How do presigned URLs work and when would you use them?
