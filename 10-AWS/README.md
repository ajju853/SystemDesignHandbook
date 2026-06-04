# 07 — Cloud Architecture

> Master cloud infrastructure across AWS, GCP, and Azure.

## Topics

| # | Topic | Description |
|---|-------|-------------|
| 1 | [AWS Overview](01-aws-overview.md) | Core AWS services |
| 2 | [GCP Overview](02-gcp-overview.md) | Core GCP services |
| 3 | [Azure Overview](03-azure-overview.md) | Core Azure services |
| 4 | [EC2 & Compute](04-ec2-compute.md) | Virtual machines and scaling |
| 5 | [Lambda & Serverless](05-lambda-serverless.md) | Serverless computing |
| 6 | [Kubernetes](06-kubernetes.md) | Container orchestration |
| 7 | [Docker](07-docker.md) | Containerization |
| 8 | [VPC & Networking](08-vpc-networking.md) | Cloud networking |
| 9 | [S3 & Storage](09-s3-storage.md) | Object and block storage |
| 10 | [CloudFront & CDN](10-cloudfront-cdn.md) | Content delivery |
| 11 | [RDS & Databases](11-rds-databases.md) | Managed databases |
| 12 | [IAM & Security](12-iam-security.md) | Identity and access management |
| 13 | [EKS, GKE, AKS](13-eks-gke-aks.md) | Managed Kubernetes |

```mermaid
graph TD
    AWS[AWS Cloud] --> Compute[Compute]
    AWS --> Storage[Storage]
    AWS --> Database[Database]
    AWS --> Networking[Networking]
    AWS --> Security[Security & IAM]
    Compute --> EC2[EC2]
    Compute --> Lambda[Lambda]
    Compute --> ECS[ECS / EKS]
    Storage --> S3[S3]
    Storage --> EBS[EBS]
    Storage --> EFS[EFS]
    Database --> RDS[RDS]
    Database --> DynamoDB[DynamoDB]
    Database --> ElastiCache[ElastiCache]
    Networking --> VPC[VPC]
    Networking --> CloudFront[CloudFront]
    Networking --> Route53[Route 53]
    Security --> IAM[IAM]
    Security --> KMS[KMS]
    Security --> WAF[WAF / Shield]
```

---

Previous: [06 — Distributed Systems](../06-Distributed-Systems/README.md)
Next: [08 — Security](../08-Security/README.md)
