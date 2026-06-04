# Lambda & Serverless

## Definition
AWS Lambda runs code without provisioning servers. You pay only for compute time (per-millisecond).

## Lambda Anatomy

```
Event Source ──► Lambda Function ──► Destination
    │                                  │
    ▼                                  ▼
API Gateway                     DynamoDB
S3 Bucket                       SQS
SQS Queue                       SNS
DynamoDB Streams                Step Functions
CloudWatch Events               Lambda (chain)
```

## Serverless Best Practices

| Practice | Why |
|----------|-----|
| **Cold start optimization** | Minimize startup latency |
| **Provisioned concurrency** | Pre-warm function instances |
| **Lambda@Edge** | Run at CloudFront edges |
| **Step Functions** | Orchestrate workflows |
| **Lambda layers** | Share dependencies |
| **Power tuning** | Optimize memory/CPU cost |

## Serverless vs Containers

| Aspect | Lambda | ECS/EKS |
|--------|--------|---------|
| Cold start | Yes (50-5000ms) | No |
| Max timeout | 15 min | None |
| Max memory | 10GB | Instance limit |
| State | Stateless | Stateful possible |
| Cost | Per-invocation | Per-hour |
| Concurrent exec | 1000 (soft) | Instance limit |

## Interview Questions
1. What causes Lambda cold starts and how do you reduce them?
2. How does Lambda scale under high concurrency?
3. Compare AWS Lambda, Google Cloud Functions, and Azure Functions
4. Design a serverless data processing pipeline
5. When would you NOT use serverless architecture?
