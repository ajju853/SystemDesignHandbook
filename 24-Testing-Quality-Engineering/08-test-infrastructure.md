# 08 - Test Infrastructure

## Architecture Overview

```mermaid
graph TB
    subgraph "Test Infrastructure Components"
        TC["Testcontainers<br/>Docker-based services"]
        EPHEMERAL["Ephemeral Environments<br/>Per-branch / Per-PR"]
        PREVIEW["Preview Deployments<br/>Vercel / Netlify"]
        DB_SEED["Database Seeding<br/>Test data strategy"]
        TDM["Test Data Management<br/>Data lifecycle"]
        PARALLEL["Parallel Execution<br/>Sharding & Distribution"]
    end

    subgraph "CI Test Architecture"
        PIPELINE["CI Pipeline<br/>GitHub Actions / Jenkins"]
        PIPELINE --> BUILD["Build & Cache"]
        BUILD --> UNIT["Unit Tests<br/>Fast, no env"]
        UNIT --> INTEGRATION["Integration Tests<br/>Testcontainers"]
        INTEGRATION --> E2E["E2E Tests<br/>Ephemeral Env"]
        E2E --> REPORT["Reports & Quality Gates"]
    end

    subgraph "Environment Types"
        LOCAL["Local Dev"] --> DEV_INT["Dev/Integration"]
        DEV_INT --> FEATURE["Feature/Branch"]
        FEATURE --> STAGING["Staging"]
        STAGING --> PROD["Production"]
    end

    TC --> INTEGRATION
    EPHEMERAL --> FEATURE
    PREVIEW --> E2E
```

## What Is Test Infrastructure?

Test infrastructure encompasses all the tooling, services, and environments required to run automated tests reliably and efficiently. It includes containerized dependencies for integration tests, ephemeral test environments, CI pipeline configuration, test data management, and parallel execution infrastructure.

## Why It Was Created

As systems grow in complexity, running tests with real dependencies becomes challenging. Teams need reliable, fast, isolated, and reproducible test environments. Without proper infrastructure, tests become flaky, slow, and unreliable — eroding confidence in the test suite.

## When to Use

- When tests depend on databases, message queues, or external services
- When running tests in CI at scale (1000s of tests)
- When multiple developers work on the same codebase
- When you need production-like environments for pre-release validation
- When test data management becomes a bottleneck

## Architecture Deep-Dive

### Testcontainers

Testcontainers provides disposable Docker containers for integration testing:

```java
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.containers.KafkaContainer;
import org.testcontainers.containers.MongoDBContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

@Testcontainers
class MultiServiceIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15")
        .withDatabaseName("testdb")
        .withUsername("test")
        .withPassword("test");

    @Container
    static KafkaContainer kafka = new KafkaContainer(
        DockerImageName.parse("confluentinc/cp-kafka:7.4.0")
    );

    @Container
    static MongoDBContainer mongo = new MongoDBContainer("mongo:6.0");

    @Test
    void shouldProcessMessageThroughFullPipeline() {
        // All three containers are running
        // Write to Kafka, store in PostgreSQL, read from MongoDB
    }
}
```

**Module-specific containers**:
```java
// Custom container for a specific service
public class PaymentServiceContainer extends GenericContainer<PaymentServiceContainer> {
    public PaymentServiceContainer() {
        super(DockerImageName.parse("payment-service:latest"));
        withExposedPorts(8080);
        withEnv("DB_URL", "jdbc:postgresql://host.docker.internal:5432/testdb");
        withEnv("KAFKA_BOOTSTRAP_SERVERS", "host.docker.internal:9092");
        waitingFor(Wait.forHttp("/health").forStatusCode(200));
    }
}
```

### Ephemeral Test Environments

```mermaid
graph LR
    PR["PR Created"] --> TRIGGER["Trigger: Build & Deploy"]
    TRIGGER --> BUILD_ENV["Build Environment Image"]
    BUILD_ENV --> DEPLOY["Deploy to Ephemeral<br/>Namespace or VM"]
    DEPLOY --> SEED["Seed Test Data"]
    SEED --> RUN_TESTS["Run Test Suite"]
    RUN_TESTS --> CLEANUP["Teardown Environment"]
    CLEANUP --> REPORT["Post Results to PR"]
```

**Kubernetes-based ephemeral environment**:

```yaml
# ephemeral-env-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: ephemeral-env-pr-123
  namespace: ephemeral-envs
spec:
  template:
    spec:
      containers:
        - name: setup
          image: alpine/k8s:1.28
          command:
            - /bin/sh
            - -c
            - |
              kubectl create namespace pr-123
              kubectl apply -f k8s/services/ -n pr-123
              kubectl apply -f k8s/database/ -n pr-123
              kubectl wait --for=condition=ready pod --all -n pr-123 --timeout=300s
              echo "Environment ready at pr-123.example.com"
```

### Preview Deployments

```yaml
# vercel-preview.yml (Vercel preview deployments)
name: Preview Deploy
on: pull_request

jobs:
  deploy-preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          scope: ${{ secrets.VERCEL_SCOPE }}
```

```yaml
# netlify-preview.yml
name: Netlify Preview
on: pull_request

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: nwtgck/actions-netlify@v2
        with:
          publish-dir: './build'
          production-branch: main
          github-token: ${{ secrets.GITHUB_TOKEN }}
          deploy-message: "Preview deploy for PR #${{ github.event.number }}"
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

### Database Seeding Strategies

```python
# seed_strategies.py
from enum import Enum
from dataclasses import dataclass

class SeedStrategy(Enum):
    FRESH = "fresh"                    # Clean DB, run all migrations, seed
    BASELINE = "baseline"              # Restore from baseline dump
    INCREMENTAL = "incremental"        # Apply changes to existing DB
    PRODUCTION_SNAPSHOT = "snapshot"   # Anonymized production data
    HYBRID = "hybrid"                  # Baseline + test-specific data

@dataclass
class SeedConfig:
    strategy: SeedStrategy
    migrations_path: str
    seed_data_path: str
    anonymize: bool = True

def setup_database(config: SeedConfig):
    if config.strategy == SeedStrategy.FRESH:
        run_migrations(config.migrations_path)
        load_seed_data(config.seed_data_path)
    elif config.strategy == SeedStrategy.BASELINE:
        restore_snapshot("baseline.sql.gz")
    elif config.strategy == SeedStrategy.PRODUCTION_SNAPSHOT:
        restore_snapshot("production_anonymized.sql.gz")
    elif config.strategy == SeedStrategy.HYBRID:
        restore_snapshot("baseline.sql.gz")
        run_migrations(config.migrations_path)
        load_seed_data(config.seed_data_path)
```

**Database seeding with Docker**:

```bash
#!/bin/bash
# seed-test-db.sh
DB_CONTAINER="test-postgres"
DB_NAME="testdb"

echo "Starting PostgreSQL container"
docker run -d --name $DB_CONTAINER \
  -e POSTGRES_DB=$DB_NAME \
  -e POSTGRES_USER=test \
  -e POSTGRES_PASSWORD=test \
  -p 5432:5432 \
  postgres:15

echo "Waiting for PostgreSQL to be ready"
until docker exec $DB_CONTAINER pg_isready; do
  sleep 1
done

echo "Running migrations"
docker run --rm --network=host \
  -v $(pwd)/migrations:/migrations \
  migrate/migrate -path=/migrations \
  -database "postgres://test:test@localhost:5432/$DB_NAME?sslmode=disable" up

echo "Seeding test data"
docker exec -i $DB_CONTAINER psql -U test -d $DB_NAME < test/fixtures/seed.sql

echo "Database ready"
```

### Parallel Test Execution

```mermaid
graph TB
    subgraph "Test Splitting Strategies"
        S1["By File<br/>Static split by test file"]
        S2["By Timing<br/>Dynamic split by history"]
        S3["By Module<br/>Logical grouping"]
        S4["By Tag<br/>Custom categorization"]
    end

    subgraph "Execution Model"
        QUEUE["Test Queue"] --> W1["Worker 1"]
        QUEUE --> W2["Worker 2"]
        QUEUE --> W3["Worker 3"]
        QUEUE --> WN["Worker N"]
        W1 --> R1["Results"]
        W2 --> R2["Results"]
        W3 --> R3["Results"]
        WN --> RN["Results"]
    end

    subgraph "Aggregation"
        R1 --> MERGE["Merge Results"]
        R2 --> MERGE
        R3 --> MERGE
        RN --> MERGE
        MERGE --> REPORT["Unified Report"]
    end
```

**GitHub Actions parallel matrix**:

```yaml
name: Parallel Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        shard: [1, 2, 3, 4]

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s

      redis:
        image: redis:7
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          java-version: '17'
          cache: maven

      - run: mvn test -pl payment-service -Dshard=${{ matrix.shard }} -DtotalShards=4

      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: test-results-${{ matrix.shard }}
          path: payment-service/target/surefire-reports/

  merge-reports:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v3
      - run: |
          mkdir -p merged-reports
          find . -name "*.xml" -exec cp {} merged-reports/ \;
      - uses: dorny/test-reporter@v1
        with:
          name: Merged Test Results
          path: merged-reports/*.xml
          reporter: java-junit
```

### CI Test Architecture

```yaml
# .github/workflows/test-pipeline.yml
name: Test Pipeline
on:
  push:
    branches: [main]
  pull_request:
    types: [opened, synchronize]

env:
  CI: true
  DOCKER_BUILDKIT: 1

jobs:
  lint-and-typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
          cache: npm
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck

  unit-tests:
    needs: lint-and-typecheck
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          java-version: '17'
          cache: maven
      - run: mvn test -DtestGroups=unit
      - uses: actions/upload-artifact@v3
        with:
          name: unit-test-results
          path: target/surefire-reports/

  integration-tests:
    needs: unit-tests
    runs-on: ubuntu-latest
    strategy:
      matrix:
        shard: [1, 2, 3]
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test
        options: --health-cmd pg_isready --health-interval 10s
      kafka:
        image: confluentinc/cp-kafka:7.4.0
        env:
          KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          java-version: '17'
          cache: maven
      - run: mvn verify -DtestGroups=integration -Dshard=${{ matrix.shard }} -DtotalShards=4

  e2e-tests:
    needs: integration-tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm ci
      - run: npm run build
      - run: npm start &
      - run: npx playwright test
      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: e2e-test-report
          path: playwright-report/

  quality-gate:
    if: always()
    needs: [unit-tests, integration-tests, e2e-tests]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v3
      - name: Check quality gate
        run: |
          # Check all test results passed
          # Check coverage threshold
          # Check flaky test count
          echo "Quality gate evaluation complete"
```

## Hands-On Example

### Complete Testcontainers Setup

```java
@SpringBootTest
@Testcontainers
class PaymentServiceFullIntegrationTest {

    private static final DockerImageName POSTGRES_IMAGE =
        DockerImageName.parse("postgres:15");
    private static final DockerImageName KAFKA_IMAGE =
        DockerImageName.parse("confluentinc/cp-kafka:7.4.0");
    private static final DockerImageName REDIS_IMAGE =
        DockerImageName.parse("redis:7-alpine");

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>(POSTGRES_IMAGE)
        .withDatabaseName("payment_test")
        .withUsername("test")
        .withPassword("test")
        .withInitScript("sql/init-schema.sql");

    @Container
    static KafkaContainer kafka = new KafkaContainer(KAFKA_IMAGE)
        .withEnv("KAFKA_TRANSACTION_STATE_LOG_MIN_ISR", "1");

    @Container
    static GenericContainer<?> redis = new GenericContainer<>(REDIS_IMAGE)
        .withExposedPorts(6379);

    @Container
    static PaymentServiceContainer paymentService = new PaymentServiceContainer()
        .withEnv("DB_URL", postgres::getJdbcUrl)
        .withEnv("KAFKA_BOOTSTRAP_SERVERS", kafka::getBootstrapServers)
        .withEnv("REDIS_HOST", redis::getHost)
        .withEnv("REDIS_PORT", () -> String.valueOf(redis.getMappedPort(6379)))
        .waitingFor(Wait.forHttp("/health").forStatusCode(200));

    @Test
    void shouldProcessPaymentThroughCompletePipeline() {
        RestTemplate rest = new RestTemplate();
        String url = String.format(
            "http://%s:%d/api/payments",
            paymentService.getHost(),
            paymentService.getMappedPort(8080)
        );

        PaymentRequest request = new PaymentRequest(100.00, "USD");
        ResponseEntity<PaymentResponse> response = rest.postForEntity(
            url, request, PaymentResponse.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getStatus()).isEqualTo("completed");
    }
}
```

### Terraform for Ephemeral Environments

```hcl
# terraform/ephemeral-env/main.tf
variable "pr_number" {
  type = string
}

variable "commit_sha" {
  type = string
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "ephemeral" {
  metadata {
    name = "pr-${var.pr_number}"
    labels = {
      environment = "ephemeral"
      pr          = var.pr_number
    }
  }
}

resource "kubernetes_deployment" "payment_service" {
  metadata {
    name      = "payment-service"
    namespace = kubernetes_namespace.ephemeral.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "payment-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "payment-service"
        }
      }

      spec {
        container {
          image = "payment-service:${var.commit_sha}"
          name  = "payment-service"

          port {
            container_port = 8080
          }

          env {
            name  = "DB_URL"
            value = "jdbc:postgresql://postgres.ephemeral.svc.cluster.local:5432/payments"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "payment_service" {
  metadata {
    name      = "payment-service"
    namespace = kubernetes_namespace.ephemeral.metadata[0].name
  }

  spec {
    selector = {
      app = "payment-service"
    }

    port {
      port        = 80
      target_port = 8080
    }
  }
}
```

### Test Data Management Strategy

```python
# test_data_manager.py
import json
import random
import hashlib
from datetime import datetime, timedelta

class TestDataManager:
    def __init__(self, environment="test"):
        self.environment = environment
        self.data_store = {}

    def anonymize_production_data(self, input_file, output_file):
        with open(input_file) as f:
            data = json.load(f)

        for record in data:
            record["email"] = f"user{record['id']}@test.example.com"
            record["name"] = f"Test User {record['id']}"
            record["phone"] = f"+1-555-{random.randint(1000,9999)}"
            record["address"] = {
                "street": f"{random.randint(1,999)} Test St",
                "city": "Testville",
                "zip": str(random.randint(10000, 99999))
            }

        with open(output_file, "w") as f:
            json.dump(data, f, indent=2)

    def create_test_fixtures(self, count=100):
        fixtures = []
        for i in range(count):
            fixtures.append({
                "id": i,
                "amount": round(random.uniform(10, 1000), 2),
                "currency": random.choice(["USD", "EUR", "GBP", "JPY"]),
                "status": random.choice(["pending", "completed", "failed"]),
                "created_at": (
                    datetime.now() - timedelta(days=random.randint(0, 30))
                ).isoformat()
            })
        return fixtures

    def generate_data_hash(self, data):
        return hashlib.sha256(json.dumps(data, sort_keys=True).encode()).hexdigest()

tdm = TestDataManager()
tdm.anonymize_production_data("prod_data.json", "test_data.json")
print(f"Data hash: {tdm.generate_data_hash(tdm.create_test_fixtures())}")
```

## Pricing / Cost Considerations

| Component | Cost |
|-----------|------|
| Testcontainers | Free (OSS) |
| Docker Desktop (CI) | $5-15/dev/month or free for OSS |
| Ephemeral environments (K8s) | $100-2000/month based on usage |
| Preview deployments (Vercel) | Free tier / $20-200/month |
| Test data storage | $50-500/month |
| CI runner compute | $200-3000/month |
| Parallel execution licenses | $0-1000/month |

## Best Practices

1. **Containerize all test dependencies** — database, queue, cache
2. **Use ephemeral environments per PR** — isolate test execution
3. **Seed test data programmatically** — reproducible test state
4. **Parallelize test execution** — reduce CI feedback time
5. **Cache dependencies** — Docker layers, Maven/Gradle cache
6. **Clean up environments automatically** — avoid resource leaks
7. **Use init scripts for database setup** — schema + seed data
8. **Monitor test infrastructure cost** — right-size resources
9. **Implement health checks for test services** — wait for readiness
10. **Document environment setup** — onboarding and debugging

## Interview Questions

1. How do Testcontainers improve integration testing reliability?
2. Explain the ephemeral environment pattern and its benefits.
3. How do you manage test data for parallel test execution?
4. What strategies do you use for database seeding in CI?
5. How do you design a CI test pipeline for a microservices architecture?
6. How do you handle flaky tests related to test infrastructure?
7. What's the difference between preview deployments and staging environments?
8. How do you optimize test execution time through infrastructure changes?
9. How do you ensure test environments are production-like?
10. How do you manage costs for test infrastructure at scale?

## Real Company Usage Examples

| Company | Practice | Impact |
|---------|----------|--------|
| Spotify | Testcontainers for backend service tests | Consistent test environments |
| Shopify | Ephemeral environments for every PR | Rapid review and merge |
| Netflix | Containerized test dependencies | Reproducible chaos experiments |
| Vercel | Preview deployments integrated with CI | Instant feature review |
| Airbnb | Test data management with anonymized production data | Realistic tests, no PII risk |
| GitHub | Parallel test matrix across shards | 10x faster test execution |
| Uber | Ephemeral environments in Kubernetes | Isolated testing at scale |
| Slack | Testcontainers + real dependencies | High-fidelity integration tests |
| Dropbox | Database seeding strategies for CI | Consistent, fast test setup |
| Lyft | Ephemeral environments with Envoy sidecar | Service mesh compatibility testing |
