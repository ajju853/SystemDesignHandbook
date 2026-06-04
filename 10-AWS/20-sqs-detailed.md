# AWS SQS Deep Dive

## What is it?
Amazon Simple Queue Service (SQS) is a fully managed message queuing service that enables decoupling of microservices, distributed systems, and serverless applications. It offers two queue types — Standard (high throughput, at-least-once) and FIFO (exactly-once, ordered).

## Why it was created
Building reliable, decoupled distributed systems requires message queuing, but managing your own message broker (RabbitMQ, ActiveMQ) requires provisioning servers, handling durability, replication, and cluster management. SQS was created to provide a fully managed, infinitely scalable message queue with no operational overhead.

## When should you use it
- **Decouple microservices**: Buffer work between producers and consumers
- **Async processing**: Offload time-consuming tasks to background workers
- **Work queues**: Distribute tasks across multiple workers (competing consumers)
- **Request buffering**: Smooth out traffic spikes between services
- **Fan-out patterns**: SQS + SNS for multi-consumer message delivery
- **Batch processing**: Accumulate messages for batch processing (e.g., write to Redshift every 100 messages)

## Architecture

```mermaid
graph TD
    subgraph "Queue Types"
        Standard[SQS Standard<br/>Unlimited TPS, at-least-once]
        FIFO[SQS FIFO<br/>300 TPS, exactly-once, ordered]
    end

    subgraph "Producers"
        Lambda[Lambda]
        EC2[EC2 Application]
        SNS[SNS Topic]
        API[API Gateway]
        SDK[AWS SDK / CLI]
    end

    subgraph "Consumers"
        Lambda_Consumer[Lambda (Event Source Mapping)]
        EC2_Consumer[EC2 / ECS - Long Polling]
        SDK_Consumer[SDK - ReceiveMessage API]
    end

    subgraph "Features"
        DLQ[Dead-Letter Queue<br/>Redirect failed messages after N retries]
        VT[Visibility Timeout<br/>Hide msg while processing (30s-12h)]
        LP[Long Polling<br/>Reduce empty responses, $]
        Delay[Delay Queue<br/>Delay delivery up to 15 min]
        Dedup[Content-Based Deduplication<br/>FIFO only - SHA-256 hash]
        Batch[Batch Operations<br/>Up to 10 msgs per call]
        Encrypt[Server-Side Encryption<br/>KMS - AES-256]
    end

    Lambda --> Standard
    EC2 --> Standard
    SNS --> Standard
    SNS --> FIFO
    Standard --> DLQ
    FIFO --> DLQ
    Standard --> Lambda_Consumer
    Standard --> EC2_Consumer
    FIFO --> Lambda_Consumer
    FIFO --> EC2_Consumer
    Standard --> VT
    Standard --> LP
    Standard --> Delay
    FIFO --> Dedup
    Standard --> Batch
    FIFO --> Batch
    Standard --> Encrypt
    FIFO --> Encrypt
```

## Hands-on Example

```bash
# Create Standard queue
aws sqs create-queue \
    --queue-name order-processing-queue \
    --attributes '{
        "VisibilityTimeout": "30",
        "MessageRetentionPeriod": "345600",
        "DelaySeconds": "0",
        "ReceiveMessageWaitTimeSeconds": "20",
        "RedrivePolicy": "{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:123456789012:order-processing-dlq\",\"maxReceiveCount\":\"3\"}"
    }'

# Create FIFO queue
aws sqs create-queue \
    --queue-name order-processing.fifo \
    --attributes '{
        "FifoQueue": "true",
        "ContentBasedDeduplication": "true",
        "DeduplicationScope": "messageGroup",
        "FifoThroughputLimit": "perQueue",
        "VisibilityTimeout": "60"
    }'

# Send message (Standard)
aws sqs send-message \
    --queue-url https://sqs.us-east-1.amazonaws.com/123456789012/order-processing-queue \
    --message-body '{"orderId": "ORD-001", "amount": 99.95}'

# Send message (FIFO - requires MessageGroupId)
aws sqs send-message \
    --queue-url https://sqs.us-east-1.amazonaws.com/123456789012/order-processing.fifo \
    --message-body '{"orderId": "ORD-002", "amount": 49.95}' \
    --message-group-id "orders-group-1" \
    --message-deduplication-id "ORD-002-1712567890"

# Receive messages (long polling)
aws sqs receive-message \
    --queue-url https://sqs.us-east-1.amazonaws.com/123456789012/order-processing-queue \
    --wait-time-seconds 20 \
    --max-number-of-messages 10 \
    --visibility-timeout 60

# Batch send messages
aws sqs send-message-batch \
    --queue-url https://sqs.us-east-1.amazonaws.com/123456789012/order-processing-queue \
    --entries '[
        {"Id": "msg1", "MessageBody": "{\"orderId\":\"ORD-003\"}", "DelaySeconds": 0},
        {"Id": "msg2", "MessageBody": "{\"orderId\":\"ORD-004\"}", "DelaySeconds": 0},
        {"Id": "msg3", "MessageBody": "{\"orderId\":\"ORD-005\"}", "DelaySeconds": 0}
    ]'
```

## Pricing Model
- **Standard queue**: $0.40 per million requests (first 1 billion/month), $0.20 per million after
- **FIFO queue**: $0.50 per million requests (first 1 billion/month)
- **Data transfer**: $0.09/GB out to internet (first 1 GB free)
- **Free tier**: 1 million requests per month

## Best Practices
- **Use FIFO for exactly-once processing**: When order and deduplication matter (financial transactions, event sourcing)
- **Use Standard for high throughput**: When at-least-once is acceptable (logging, notifications)
- **Always configure a Dead-Letter Queue**: Capture messages that fail after maxReceiveCount retries
- **Use long polling**: Set `ReceiveMessageWaitTimeSeconds` ≥ 20 to reduce empty responses (saves cost and latency)
- **Visibility timeout = processing time × 6**: Allow at least 6 retries before the message goes to DLQ
- **Use batch operations**: Up to 10 messages per API call (reduces cost by 10x)
- **Consumer idempotency**: Standard queues can deliver duplicates — design consumers to handle this

## Interview Questions
1. What's the difference between Standard and FIFO queues?
2. How does visibility timeout work and what happens when it expires?
3. What is a dead-letter queue and how do you configure it?
4. How does long polling differ from short polling?
5. How would you design a fan-out pattern with SQS and SNS?

## Real Company Usage
**Airbnb** uses SQS to decouple their booking pipeline — when a booking is made, the request goes to an SQS queue and multiple worker services process it asynchronously. **Capital One** uses SQS with FIFO queues for financial transactions, ensuring exactly-once processing and ordered delivery of payment events.
