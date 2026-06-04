# AWS Overview

## Core Services Map

```
Compute           Storage         Database        Networking
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ EC2      │    │ S3       │    │ RDS      │    │ VPC      │
│ Lambda   │    │ EBS      │    │ DynamoDB │    │ Route 53 │
│ ECS/EKS  │    │ EFS      │    │ Aurora   │    │ CloudFront│
│ Fargate  │    │ Glacier  │    │ ElastiCache│   │ API GW   │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

## Well-Architected Framework

1. **Operational Excellence** — Monitor, automate, improve
2. **Security** — IAM, encryption, compliance
3. **Reliability** — Recovery, scaling, backups
4. **Performance Efficiency** — Right-sizing, serverless
5. **Cost Optimization** — Reserved instances, spot instances
6. **Sustainability** — Carbon footprint reduction

## Common Architecture Patterns

| Pattern | Services |
|---------|----------|
| **Web App** | Route53 → CloudFront → ALB → EC2/ECS → RDS → ElastiCache |
| **Serverless** | API Gateway → Lambda → DynamoDB → SQS → S3 |
| **Event-driven** | S3 Event → SQS → Lambda → DynamoDB |
| **Microservices** | EKS/ECS → RDS → MSK → ElastiCache → ALB |
| **Data Pipeline** | Kinesis → Lambda → S3 → Athena → QuickSight |

## Interview Questions
1. How does AWS's shared responsibility model work?
2. Design a highly available architecture on AWS
3. Compare EC2, Lambda, and ECS for web applications
4. How would you migrate a monolith to AWS?
5. What's the difference between a VPC, subnet, and security group?
