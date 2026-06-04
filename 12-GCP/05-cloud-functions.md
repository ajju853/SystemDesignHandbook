# Cloud Functions

## What is it?
Cloud Functions is a FaaS (Function-as-a-Service) platform that lets you run single-purpose code in response to cloud events without managing servers. 1st gen (v1) is based on event-driven architecture; 2nd gen (v2) is built on Cloud Run and Eventarc.

## Why it was created
Developers need to react to infrastructure events (file uploads, database changes, pub/sub messages) without provisioning servers or containers. Cloud Functions provides the simplest deployment model: write code, set a trigger, and go.

## When should you use it
- Lightweight HTTP APIs and webhooks
- Event-driven processing: Cloud Storage object changes, Pub/Sub messages, Firestore writes
- Real-time image/video processing
- Data transformation and ETL pipelines
- Scheduled tasks (via Cloud Scheduler)
- Integrating third-party services (Slack bots, Stripe webhooks)

## Architecture

```mermaid
graph LR
    subgraph Triggers
        HTTP[HTTP Request]
        GCS[Cloud Storage]
        PS[Pub/Sub]
        FS[Firestore]
        SCH[Cloud Scheduler]
    end
    subgraph 2nd Gen (Cloud Run based)
        GCF[Cloud Function v2]
        GCF --> VPC[VPC Connector]
    end
    subgraph 1st Gen
        F1[Cloud Function v1]
    end
    HTTP --> GCF
    GCS --> Eventarc --> GCF
    PS --> Eventarc --> GCF
    FS --> GCF
    SCH --> PS --> GCF
```

## 1st Gen vs 2nd Gen

| Feature | 1st Gen | 2nd Gen (Cloud Run based) |
|---------|---------|---------------------------|
| **Runtime** | Custom per-language | Container-based (Dockerfile) |
| **Triggers** | HTTP, Storage, Pub/Sub, Firestore, Firebase | All Eventarc sources + HTTP |
| **Concurrency** | 1 per instance | Up to 1000 per instance |
| **Min instances** | No | Yes (cold start mitigation) |
| **Max timeout** | 9 minutes (540s) | 60 minutes |
| **Max memory** | 8 GB | 32 GB |
| **Networking** | Limited VPC access | Full VPC via Serverless VPC Connector |
| **Request rate** | 1000/min per function | Unlimited (Cloud Run scale) |
| **URL** | `region-project.cloudfunctions.net` | `function-name-uid-reg.a.run.app` |
| **Status** | GA (not recommended for new functions) | GA (recommended) |

## Triggers

| Trigger | Event | Use Case |
|---------|-------|----------|
| **HTTP** | HTTP request | REST API, webhooks |
| **Cloud Storage** | Object create/delete/archive | Image processing, file validation |
| **Pub/Sub** | Message published | Async processing, event routing |
| **Firestore** | Document create/update/delete | Sync search index, send notifications |
| **Firebase** | Firebase events | Mobile app analytics, auth triggers |
| **Cloud Scheduler** | Scheduled HTTP | Cron jobs, periodic tasks |

## Background vs HTTP Functions
- **HTTP functions**: Invoked via HTTP(S) requests; have a web endpoint
- **Background functions** (1st gen): Invoked by event source; receive event payload
- **CloudEvent functions** (2nd gen): Invoked by Eventarc; receive CloudEvents format

## Min / Max Instances
- **min_instances**: Keep N instances warm (reduces cold starts, increases cost)
- **max_instances**: Prevents runaway scaling (limits concurrency to non-HTTP-friendly backends)
- Only available in 2nd gen (set via `--min-instances` flag)

## Networking
- **1st gen**: Can use VPC Connector or Serverless VPC Access (egress only; limited ingress)
- **2nd gen**: Full VPC connectivity via Serverless VPC Connector (same as Cloud Run)
- Ingress settings: ALLOW_ALL, ALLOW_INTERNAL_ONLY, ALLOW_INTERNAL_AND_GCLB

## Environment Variables
- Set at deploy time via `--set-env-vars KEY=VALUE`
- Can be marked as secret references (value stored in Secret Manager)
- Available at function runtime via `process.env` (Node.js), `os.environ` (Python), etc.

## Secrets
- Reference secrets from Secret Manager as environment variables or mounted volumes
- 1st gen: only as environment variables
- 2nd gen: as env vars or file mounts
```bash
gcloud functions deploy my-function \
  --set-secrets='DB_PASSWORD=my-secret:latest'
```

## Cloud Functions vs Cloud Run

| Aspect | Cloud Functions | Cloud Run |
|--------|-----------------|-----------|
| **Deployment** | Source code only | Container image |
| **Control** | Limited (runtime versions) | Full (any binary, any OS) |
| **Concurrency** | 1 (1st gen) or configurable (2nd gen) | Configurable up to 1000 |
| **Timeout** | 9m (1st gen) or 60m (2nd gen) | 60m (service), 24h (job) |
| **Trigger types** | GCP events + HTTP | HTTP + Eventarc |
| **Port** | Fixed (framework-defined) | Configurable |
| **Best for** | Simple event handlers | Full microservices |

## Hands-on Example

```bash
# Deploy HTTP function (2nd gen)
gcloud functions deploy hello-http \
  --gen2 \
  --runtime=nodejs20 \
  --region=us-central1 \
  --source=. \
  --entry-point=helloHttp \
  --trigger-http \
  --allow-unauthenticated

# Deploy Cloud Storage function (2nd gen)
gcloud functions deploy process-image \
  --gen2 \
  --runtime=python311 \
  --region=us-central1 \
  --source=. \
  --entry-point=process_image \
  --trigger-event-filters="type=google.cloud.storage.object.v1.finalized" \
  --trigger-event-filters="bucket=my-image-bucket"

# Deploy Pub/Sub function (2nd gen)
gcloud functions deploy handle-message \
  --gen2 \
  --runtime=go121 \
  --region=us-central1 \
  --source=. \
  --entry-point=HandleMessage \
  --trigger-topic=my-topic

# With min instances (cold start mitigation)
gcloud functions deploy critical-api \
  --gen2 \
  --runtime=nodejs20 \
  --min-instances=2 \
  --max-instances=50 \
  --trigger-http
```

## Pricing Model
- **1st gen**: Per 100ms increments (minimum 100ms), including idle time
- **2nd gen**: Same pricing as Cloud Run per vCPU-second and memory-second
- **Invocations**: $0.40 per million invocations (free tier: 2M/month)
- **Compute time**: $0.0000025 per GHz-second (free tier: 400K GB-seconds, 200K GHz-seconds)
- **Egress**: Standard network egress charges apply

## Best Practices
- Use 2nd gen for all new functions (1st gen is legacy)
- Keep functions single-purpose and stateless
- Set max instances to prevent cost spikes
- Use Cloud Event format for 2nd gen for better portability
- Use Secret Manager for sensitive config (never hardcode secrets)
- Set up error handling and dead-letter queues for event-driven functions
- Use Cloud Run for anything more complex than a single-purpose function
- Monitor with Cloud Logging and set up error reporting

## Interview Questions
1. What are the key differences between Cloud Functions 1st gen and 2nd gen?
2. How does Cloud Functions compare to Cloud Run in terms of concurrency, timeout, and control?
3. What triggers are available and how do you set up event-driven processing with Cloud Functions?
4. How do you handle cold starts in Cloud Functions 2nd gen?
5. Design an event-driven pipeline using Cloud Functions, Cloud Storage, and Pub/Sub

## Real Company Usage
- **Genies**: Uses Cloud Functions for avatar rendering triggered by user actions
- **Livongo**: Processes health device data via Cloud Functions from IoT Core
- **Equifax**: Uses Cloud Functions for real-time credit report processing
