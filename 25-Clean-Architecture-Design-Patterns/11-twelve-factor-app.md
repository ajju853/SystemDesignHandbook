# Twelve-Factor App

## Architecture Diagram

```mermaid
graph TB
    subgraph "Twelve Factors"
        F1[1. Codebase: One codebase tracked in VCS]
        F2[2. Dependencies: Explicit declaration]
        F3[3. Config: Store in environment]
        F4[4. Backing Services: Treat as attached resources]
        F5[5. Build/Release/Run: Strict separation]
        F6[6. Processes: Stateless and share-nothing]
        F7[7. Port Binding: Export services via port]
        F8[8. Concurrency: Scale out via process model]
        F9[9. Disposability: Fast startup and graceful shutdown]
        F10[10. Dev/Prod Parity: Keep environments similar]
        F11[11. Logs: Treat as event streams]
        F12[12. Admin Processes: Run as one-off processes]
    end
    F1 -->|Single codebase, multiple deploys| VCS[Git Repository]
    F2 -->|Dependency manager| PKG[package.json / Cargo.toml / requirements.txt]
    F3 -->|Environment variables| ENV[OS Environment]
    F4 -->|Resource binding| BACK[Database / Queue / Cache]
    F5 -->|Build pipeline| BLD[Build -> Release -> Run]
    F6 -->|No local state| STL[Stateless Processes]
    F7 -->|HTTP self-contained| PORT[Port Service]
    F8 -->|Process types| PROCS[Web / Worker / Scheduled]
    F9 -->|Graceful| GRACE[Start / Stop / Crash]
    F10 -->|CI/CD parity| CI[Continuous Integration]
    F11 -->|Aggregated| LOGS[Log Aggregator]
    F12 -->|Migration scripts| ONCE[One-off scripts]
    style F1 fill:#4a90d9,stroke:#fff,color:#fff
    style F2 fill:#50b86c,stroke:#fff,color:#fff
    style F3 fill:#d9a04a,stroke:#fff,color:#fff
    style F4 fill:#d94a8a,stroke:#fff,color:#fff
    style F5 fill:#7b4ad9,stroke:#fff,color:#fff
    style F6 fill:#4ad9c4,stroke:#fff,color:#fff
    style F7 fill:#d97a4a,stroke:#fff,color:#fff
    style F8 fill:#8ad94a,stroke:#fff,color:#fff
    style F9 fill:#d9c44a,stroke:#fff,color:#fff
    style F10 fill:#d94a4a,stroke:#fff,color:#fff
    style F11 fill:#4a6fd9,stroke:#fff,color:#fff
    style F12 fill:#d94a9a,stroke:#fff,color:#fff
```

## What Is the Twelve-Factor App?

The Twelve-Factor App is a **methodology for building cloud-native, software-as-a-service applications**. Created by engineers at **Heroku** (particularly Adam Wiggins) in 2011, it formalizes best practices for web applications that are deployable, scalable, and maintainable.

## Why It Was Created

Before Twelve-Factor, deploying web applications was fragile and inconsistent. Common problems included:

- **Configuration drift** between environments
- **Vendor lock-in** to specific cloud providers
- **Unreliable deployments** due to implicit dependencies
- **Scaling problems** because of local state
- **No separation** build, release, and run phases

The Twelve-Factor methodology codified the patterns that successful SaaS providers (Heroku, Engine Yard) had discovered.

## When to Use Twelve-Factor

- **Cloud-native applications** — any app deployed on PaaS or container platforms
- **Microservices** — each service should follow twelve-factor principles
- **CI/CD pipelines** — twelve-factor enables automated build/release/run
- **Multi-environment deployments** — dev, staging, production parity
- **Not for** — embedded systems, desktop applications, single-user tools

---

## Factor 1: Codebase

> One codebase tracked in revision control, many deploys.

```mermaid
graph LR
    REPO[Code Repository] -->|Build & Deploy| PROD[Production Deploy]
    REPO -->|Build & Deploy| STAG[Staging Deploy]
    REPO -->|Build & Deploy| DEV[Developer Deploy]
    REPO -->|Branch| FEAT[Feature Branch Deploy]
    style REPO fill:#4a90d9,stroke:#fff,color:#fff
```

```bash
# Good: Single repo per service
order-service/
├── src/
├── tests/
├── Dockerfile
├── package.json
├── docker-compose.yml
└── Jenkinsfile

# Different deploys use different config (Factor 3)
git checkout main
git push heroku main  # Production
git push staging main # Staging
```

**Violation**: Multiple codebases for the same app (e.g., frontend and backend in separate repos with tight coupling). Multiple apps in one repo (monorepo is acceptable but each app must have its own codebase identity).

## Factor 2: Dependencies

> Explicitly declare and isolate dependencies.

```javascript
// package.json - Explicit declaration
{
    "name": "order-service",
    "version": "1.0.0",
    "dependencies": {
        "express": "^4.18.0",
        "pg": "^8.11.0",
        "ioredis": "^5.3.0",
        "amqplib": "^0.10.0"
    },
    "devDependencies": {
        "jest": "^29.0.0",
        "typescript": "^5.0.0"
    }
}
```

```toml
# Cargo.toml (Rust) - Explicit declaration
[package]
name = "order-service"
version = "0.1.0"

[dependencies]
actix-web = "4"
sqlx = { version = "0.7", features = ["runtime-tokio", "postgres"] }
redis = { version = "0.23", features = ["tokio-comp"] }
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
```

```python
# requirements.txt - Explicit declaration
fastapi==0.104.0
uvicorn[standard]==0.24.0
asyncpg==0.29.0
redis==5.0.0
aiokafka==0.10.0
pydantic==2.4.0
```

```dockerfile
# Isolated dependency installation
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY dist/ ./dist/
USER node
CMD ["node", "dist/main.js"]
```

**Violation**: Relying on system-level packages (e.g., `apt-get install` in production), vendoring dependencies in the repo, implicit dependencies.

## Factor 3: Config

> Store config in environment variables.

```typescript
// Bad: Config in code
const config = {
    databaseUrl: "postgres://user:pass@localhost:5432/prod",
    redisUrl: "redis://localhost:6379",
    apiKey: "sk-live-abc123",
};
```

```typescript
// Good: Config from environment
const config = {
    databaseUrl: process.env.DATABASE_URL!,
    redisUrl: process.env.REDIS_URL!,
    apiKey: process.env.STRIPE_API_KEY!,
    port: parseInt(process.env.PORT ?? "8080", 10),
    logLevel: process.env.LOG_LEVEL ?? "info",
};

// Validate config at startup
function validateConfig(config: typeof rawConfig): void {
    const required = ["DATABASE_URL", "REDIS_URL", "STRIPE_API_KEY"];
    for (const key of required) {
        if (!process.env[key]) {
            throw new Error(`Missing required config: ${key}`);
        }
    }
}
```

```yaml
# docker-compose.yml - Config via environment
version: "3.8"
services:
  order-service:
    image: order-service:latest
    ports:
      - "8080:8080"
    environment:
      DATABASE_URL: "postgres://user:pass@postgres:5432/orders"
      REDIS_URL: "redis://redis:6379"
      STRIPE_API_KEY: "${STRIPE_API_KEY}"
      LOG_LEVEL: "debug"
    depends_on:
      - postgres
      - redis
```

```bash
# Kubernetes ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: order-service-config
data:
  LOG_LEVEL: "info"
  PORT: "8080"
---
apiVersion: v1
kind: Secret
metadata:
  name: order-service-secrets
stringData:
  DATABASE_URL: "postgres://..."
  STRIPE_API_KEY: "sk-live-..."
```

**Violation**: Config files committed to repo, different config per environment checked in, config as constants in code.

## Factor 4: Backing Services

> Treat backing services as attached resources.

```typescript
// Backing service: attached resource
export class DatabaseResource {
    constructor(private url: string) {}

    async connect(): Promise<Pool> {
        return new Pool({ connectionString: this.url });
    }
}

export class RedisResource {
    constructor(private url: string) {}

    async connect(): Promise<Redis> {
        return new Redis(this.url);
    }
}

// Swappable via config
const db = new DatabaseResource(process.env.DATABASE_URL!);
const redis = new RedisResource(process.env.REDIS_URL!);
```

```yaml
# Swappable in different environments
# Local dev:
environment:
  DATABASE_URL: "postgres://localhost:5432/orders"
  REDIS_URL: "redis://localhost:6379"

# Production:
environment:
  DATABASE_URL: "postgres://user:pass@rds.amazonaws.com:5432/orders"
  REDIS_URL: "redis://cluster.redis.amazonaws.com:6379"
```

```bash
# Swap database with zero code changes
# Local
export DATABASE_URL="postgres://localhost:5432/orders"

# Staging
export DATABASE_URL="postgres://staging:pass@staging-db:5432/orders"

# Production
export DATABASE_URL="postgres://prod:pass@prod-db:5432/orders"
```

**Violation**: Hardcoding database host, using localhost in code, treating production and dev resources as different.

## Factor 5: Build, Release, Run

> Strictly separate build, release, and run stages.

```mermaid
graph LR
    CODE[Code] --> BUILD[Build Stage]
    BUILD -->|+ Config| REL[Release Stage]
    REL -->|+ Config| RUN[Run Stage]
    style BUILD fill:#4a90d9,stroke:#fff,color:#fff
    style REL fill:#50b86c,stroke:#fff,color:#fff
    style RUN fill:#d9a04a,stroke:#fff,color:#fff
```

```yaml
# CI/CD Pipeline
stages:
  - build
  - release
  - deploy

build:
  stage: build
  script:
    - npm ci
    - npm run build
    - docker build -t order-service:$CI_COMMIT_SHA .
    - docker push registry.example.com/order-service:$CI_COMMIT_SHA
  artifacts:
    paths:
      - dist/

release:
  stage: release
  script:
    - docker tag registry.example.com/order-service:$CI_COMMIT_SHA registry.example.com/order-service:staging
    - docker push registry.example.com/order-service:staging

deploy:
  stage: deploy
  script:
    - kubectl set image deployment/order-service order-service=registry.example.com/order-service:$CI_COMMIT_SHA
    - kubectl rollout status deployment/order-service
  environment:
    name: production
```

```bash
# Manual release stages
# Build
docker build -t order-service:$(git rev-parse HEAD) .

# Release (build + config)
docker tag order-service:$(git rev-parse HEAD) registry.example.com/order-service:v1.2.3
docker push registry.example.com/order-service:v1.2.3

# Run
kubectl set image deployment/order-service order-service=registry.example.com/order-service:v1.2.3
```

**Violation**: Making runtime changes that aren't in the release (e.g., SSH-ing into production to change code), using code changes without a new release.

## Factor 6: Processes

> Execute the app as one or more stateless processes.

```typescript
// Stateless process: session state in backing service
import session from "express-session";
import RedisStore from "connect-redis";

app.use(session({
    store: new RedisStore({ client: redis }),
    secret: process.env.SESSION_SECRET!,
    resave: false,
    saveUninitialized: false,
}));
```

```typescript
// Stateless: all state in database/backing services
export class OrderHandler {
    async createOrder(req: Request, res: Response): Promise<void> {
        const order = await Order.create(req.body);
        // No local state - everything in DB
        res.status(201).json(order);
    }

    async getOrder(req: Request, res: Response): Promise<void> {
        const order = await Order.findById(req.params.id);
        if (!order) {
            res.status(404).json({ error: "Not found" });
            return;
        }
        res.json(order);
    }
}
```

```python
# Stateless web worker
import os
import redis
from flask import Flask, request

app = Flask(__name__)
redis_client = redis.Redis.from_url(os.environ["REDIS_URL"])

@app.route("/counter")
def counter():
    count = redis_client.incr("counter")
    return {"count": count}
```

**Violation**: Sticky sessions, local file storage, in-memory state that can't survive restart.

## Factor 7: Port Binding

> Export services via port binding.

```typescript
import express from "express";

const app = express();
const PORT = parseInt(process.env.PORT ?? "8080", 10);

app.get("/health", (req, res) => {
    res.json({ status: "ok" });
});

app.listen(PORT, () => {
    console.log(`Service listening on port ${PORT}`);
});
```

```go
package main

import (
    "net/http"
    "os"
)

func main() {
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.Write([]byte(`{"status":"ok"}`))
    })

    http.ListenAndServe(":"+port, nil)
}
```

```dockerfile
FROM node:20-alpine
EXPOSE 8080
CMD ["node", "dist/main.js"]
```

**Violation**: Running behind a separate web server (Apache, Nginx) in the container, hardcoding port, requiring a runtime server injection.

## Factor 8: Concurrency

> Scale out via the process model.

```typescript
// Cluster mode for Node.js
import cluster from "cluster";
import os from "os";

if (cluster.isPrimary) {
    const workerCount = parseInt(process.env.WEB_CONCURRENCY ?? os.cpus().toString(), 10);

    for (let i = 0; i < workerCount; i++) {
        cluster.fork();
    }

    cluster.on("exit", (worker) => {
        console.log(`Worker ${worker.process.pid} died, restarting`);
        cluster.fork();
    });
} else {
    startServer();
}
```

```yaml
# Kubernetes: scale via process model
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
spec:
  replicas: 3  # Horizontal scaling
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
    spec:
      containers:
        - name: order-service
          image: order-service:latest
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
```

```yaml
# docker-compose: process types
services:
  web:
    image: order-service:latest
    command: node dist/web.js
    ports:
      - "8080:8080"
    environment:
      PORT: "8080"

  worker:
    image: order-service:latest
    command: node dist/worker.js
    environment:
      QUEUE_URL: "amqp://rabbitmq:5672"

  scheduler:
    image: order-service:latest
    command: node dist/scheduler.js
    environment:
      SCHEDULE_INTERVAL: "*/5 * * * *"
```

**Violation**: Thread-based concurrency in shared memory, assuming single-process deployment, not designing for horizontal scale.

## Factor 9: Disposability

> Maximize robustness with fast startup and graceful shutdown.

```typescript
import { createTerminus } from "@godaddy/terminus";

const server = app.listen(PORT);

createTerminus(server, {
    signal: "SIGTERM",
    healthChecks: {
        "/health": async () => {
            // Check DB connectivity
            await db.query("SELECT 1");
            return { status: "ok" };
        },
    },
    onSignal: async () => {
        console.log("Shutting down gracefully...");
        await db.end();
        await redis.quit();
        await messageQueue.close();
    },
    onShutdown: () => {
        console.log("Cleanup finished, exiting");
    },
});
```

```dockerfile
FROM node:20-alpine
RUN apk add --no-cache dumb-init
EXPOSE 8080

USER node
CMD ["dumb-init", "node", "dist/main.js"]
```

```yaml
# Kubernetes: graceful shutdown
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
        - name: order-service
          lifecycle:
            preStop:
              exec:
                command: ["node", "dist/graceful-shutdown.js"]
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
```

**Violation**: Slow startup (minutes), processes that hang on SIGTERM, in-memory state that would be lost on crash.

## Factor 10: Dev/Prod Parity

> Keep development, staging, and production as similar as possible.

```yaml
# docker-compose.yml: same services across all environments
version: "3.8"
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: orders
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

  rabbitmq:
    image: rabbitmq:3-management

  order-service:
    build: .
    ports:
      - "8080:8080"
    depends_on:
      - postgres
      - redis
      - rabbitmq
    environment:
      DATABASE_URL: "postgres://postgres:postgres@postgres:5432/orders"
      REDIS_URL: "redis://redis:6379"
      RABBITMQ_URL: "amqp://guest:guest@rabbitmq:5672"

volumes:
  postgres_data:
```

```bash
# Same backing services, same binary, different config
# Dev
export DATABASE_URL="postgres://localhost:5432/orders_dev"
export DEBUG="true"

# Production
export DATABASE_URL="postgres://rds.example.com:5432/orders_prod"
export DEBUG="false"
```

**Violation**: Using SQLite in dev and PostgreSQL in prod, different OS, different versions of backing services.

## Factor 11: Logs

> Treat logs as event streams.

```typescript
// Structured logging to stdout
const logger = {
    info: (message: string, context?: Record<string, unknown>) => {
        console.log(JSON.stringify({
            level: "info",
            timestamp: new Date().toISOString(),
            message,
            service: "order-service",
            ...context,
        }));
    },
    error: (message: string, error?: Error, context?: Record<string, unknown>) => {
        console.error(JSON.stringify({
            level: "error",
            timestamp: new Date().toISOString(),
            message,
            error: error?.message,
            stack: error?.stack,
            service: "order-service",
            ...context,
        }));
    },
    warn: (message: string, context?: Record<string, unknown>) => {
        console.warn(JSON.stringify({
            level: "warn",
            timestamp: new Date().toISOString(),
            message,
            service: "order-service",
            ...context,
        }));
    },
};

app.use((req, res, next) => {
    const start = Date.now();
    res.on("finish", () => {
        logger.info("request", {
            method: req.method,
            path: req.path,
            status: res.statusCode,
            duration: Date.now() - start,
            requestId: req.headers["x-request-id"],
        });
    });
    next();
});
```

```python
# Structured logging
import logging
import json
import sys

class JSONFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        return json.dumps({
            "level": record.levelname.lower(),
            "timestamp": self.formatTime(record),
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
        })

handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JSONFormatter())
logging.basicConfig(handlers=[handler], level=logging.INFO)
```

```yaml
# Log aggregation in production
apiVersion: v1
kind: Pod
metadata:
  annotations:
    fluentd-sidecar-injector/container-name: order-service
spec:
  containers:
    - name: order-service
      image: order-service:latest
    - name: fluentd
      image: fluent/fluentd:v1.16
      volumeMounts:
        - name: varlog
          mountPath: /var/log
  volumes:
    - name: varlog
      emptyDir: {}
```

**Violation**: Writing logs to files, log rotation in the app, logging frameworks that buffer and batch.

## Factor 12: Admin Processes

> Run admin/management tasks as one-off processes.

```typescript
// db/migrate.ts - One-off migration script
import { Pool } from "pg";

async function migrate(): Promise<void> {
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });

    await pool.query(`
        CREATE TABLE IF NOT EXISTS orders (
            id UUID PRIMARY KEY,
            customer_id UUID NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT 'draft',
            created_at TIMESTAMP NOT NULL DEFAULT NOW()
        );
    `);

    await pool.query(`
        CREATE TABLE IF NOT EXISTS order_items (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            order_id UUID NOT NULL REFERENCES orders(id),
            product_id UUID NOT NULL,
            quantity INT NOT NULL,
            price_cents INT NOT NULL
        );
    `);

    console.log("Migration complete");
    await pool.end();
}

migrate().catch(err => {
    console.error("Migration failed:", err);
    process.exit(1);
});
```

```json
{
    "scripts": {
        "start": "node dist/main.js",
        "migrate": "node dist/db/migrate.js",
        "seed": "node dist/db/seed.js",
        "backfill": "node dist/scripts/backfill.js",
        "report": "node dist/scripts/generate-report.js"
    }
}
```

```bash
# Running admin processes
docker run --rm \
    -e DATABASE_URL=$DATABASE_URL \
    order-service:latest \
    node dist/db/migrate.js

# In Kubernetes
kubectl run migration-job \
    --image=order-service:latest \
    --restart=Never \
    --env="DATABASE_URL=$DATABASE_URL" \
    -- node dist/db/migrate.js

# Better: Kubernetes Job
kubectl apply -f migration-job.yaml
```

```yaml
# migration-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: order-migration
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migration
          image: order-service:latest
          command: ["node", "dist/db/migrate.js"]
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: url
```

**Violation**: Admin tasks embedded in web process, connecting to prod DB from local machine, running migrations as part of startup.

---

## Modern Interpretations

### Twelve-Factor for Serverless

| Factor | Serverless Adaptation |
|--------|----------------------|
| Codebase | One function repo per service |
| Dependencies | Lambda layers, dependency bundles |
| Config | Environment variables + Parameter Store |
| Backing Services | Same — treat as attached resources |
| Build/Release/Run | CI/CD pipeline builds, versioned deployments |
| Processes | Stateless functions, no local state |
| Port Binding | API Gateway + Lambda handler |
| Concurrency | Auto-scaling, concurrent function invocations |
| Disposability | Cold starts, graceful shutdown |
| Dev/Prod Parity | SAM/Serverless Framework for local dev |
| Logs | CloudWatch Logs + structured JSON |
| Admin Processes | Step Functions, EventBridge scheduled tasks |

### Twelve-Factor for Containers/Kubernetes

| Factor | Container/K8s Adaptation |
|--------|-------------------------|
| Codebase | One image per service |
| Dependencies | Container image includes all deps |
| Config | ConfigMaps + Secrets |
| Backing Services | Service discovery + DNS |
| Build/Release/Run | Docker build → image tag → deployment |
| Processes | Pods are stateless, ephemeral |
| Port Binding | Container port → service port |
| Concurrency | ReplicaSet/HPA for scaling |
| Disposability | Liveness/Readiness probes, preStop hooks |
| Dev/Prod Parity | Same image, different manifests |
| Logs | Sidecar (Fluentd) or stdout |
| Admin Processes | Jobs, CronJobs |

---

## Best Practices

1. **One codebase per service** — in a microservices architecture, each service follows twelve-factor independently
2. **Never hardcode config** — environment variables for everything environment-specific
3. **Stateless is the goal** — any state belongs in a backing service
4. **Same artifacts across environments** — build once, deploy many times
5. **Graceful shutdown handling** — SIGTERM handler for cleanup
6. **Structured logging to stdout** — let the platform handle log routing
7. **Admin tasks as one-off processes** — never in the application startup
8. **Containerize everything** — Docker ensures dependency isolation
9. **Health checks** — readiness and liveness probes for orchestration
10. **Time budget for startup** — under 30 seconds for cloud platforms

---

## Interview Questions

1. What is the Twelve-Factor App methodology?
2. Why should config be stored in environment variables, not in code?
3. How does Twelve-Factor differentiate between build, release, and run?
4. What does "disposability" mean in the context of cloud-native apps?
5. How do you handle session state in a stateless, twelve-factor app?
6. What is dev/prod parity and why is it important?
7. How are logs treated differently in Twelve-Factor vs traditional apps?
8. What is port binding and how does it relate to containers?
9. How does the concurrency factor apply to Node.js/Python/Golang apps?
10. When would you violate a Twelve-Factor principle intentionally?

---

## Real Company Usage

| Company | Application | Twelve-Factor Practice |
|---------|-------------|------------------------|
| **Heroku** | Platform itself | Origin of the methodology |
| **GitLab** | CI/CD | Environment-based config, stateless web processes |
| **Netflix** | Streaming platform | Stateless services, config-driven deployments |
| **Uber** | Ride-hailing | Process model, env-based config per microservice |
| **Airbnb** | Booking platform | One codebase per service, CI/CD parity |
| **Shopify** | E-commerce | Stateless web workers, Redis-backed sessions |
| **Spotify** | Music platform | Containerized services, logging to stdout |
