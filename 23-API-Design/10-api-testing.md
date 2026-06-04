# API Testing

> API testing validates that an API meets expectations for functionality, reliability, performance, and security. From contract tests that verify provider-consumer agreements to fuzz tests that find edge cases, comprehensive API testing ensures quality at every level.

## Architecture at a Glance

```mermaid
graph TB
    subgraph "Test Types"
        Contract["Contract Testing (Pact)"]
        Fuzz["Fuzzing / Property-Based"]
        Integration["Integration Testing"]
        Perf["Performance Testing"]
        E2E["End-to-End Testing"]
    end

    subgraph "Contract Testing"
        Consumer["Consumer Tests"]
        Consumer --> PactBroker["Pact Broker"]
        Provider["Provider Tests"]
        Provider --> PactBroker
        PactBroker --> CanIDeploy["Can I Deploy?"]
    end

    subgraph "Fuzzing"
        API_Fuzz["API Fuzzer"]
        API_Fuzz --> Inject["Inject Malformed Data"]
        Inject --> Monitor["Monitor for Crashes / Errors"]
        Fuzz --> PropertyCheck["Property-Based Checks"]
    end

    subgraph "Integration"
        TestContainer["Test Containers"]
        TestContainer --> DB["PostgreSQL"]
        TestContainer --> Cache["Redis"]
        TestContainer --> Queue["RabbitMQ"]
        TestContainer --> Mock["Mock Servers"]
    end

    subgraph "Performance"
        K6["k6 Scripts"]
        WRK["wrk / hey"]
        Gatling["Gatling"]
        K6 --> Metrics["Latency / Throughput / Errors"]
        Metrics --> Assert["Assert Thresholds"]
    end

    subgraph "CI/CD Pipeline"
        Commit["Commit"] --> Unit["Unit Tests"]
        Unit --> Contract
        Contract --> Integration
        Integration --> Perf
        Perf --> Staging["Staging Deploy"]
        Staging --> E2E
        E2E --> Prod["Production Deploy"]
        Prod --> Monitor["Production Monitoring"]
    end
```

## What is API Testing?

API testing validates APIs at the message layer — without a UI. It includes:

- **Contract testing** — ensuring provider and consumer agree on the API contract
- **Fuzzing** — sending unexpected or malformed data to find vulnerabilities
- **Property-based testing** — verifying invariants across random inputs
- **Integration testing** — testing with real dependencies (databases, queues)
- **Performance testing** — measuring latency, throughput, and resource usage
- **End-to-end testing** — full workflow across multiple services

## Why API Testing Matters

- **APIs are the integration point** — if the API breaks, everything breaks
- **Shift left** — catch issues before they reach production
- **Automated regression** — prevent accidental breaking changes
- **Documentation accuracy** — tests serve as executable specifications
- **Security** — fuzzing finds vulnerabilities before attackers do

## When to Use Each Type

| Test Type | Phase | Purpose |
|-----------|-------|---------|
| Contract | Development | API compatibility between services |
| Unit | Development | Individual endpoint logic |
| Integration | Pre-merge | Real dependency interaction |
| Fuzzing | Pre-merge | Edge cases and security |
| Performance | Pre-release | Latency/throughput validation |
| E2E | Staging | Full workflow validation |
| Monitoring | Production | Real-time API health |

## Contract Testing (Pact)

Contract testing ensures that consumer expectations match provider behavior — without expensive end-to-end tests.

### Consumer Side (Pact JS)

```javascript
// consumer.spec.js — defines what the consumer expects
const { PactV3, MatchersV3 } = require("@pact-foundation/pact");
const { like, eachLike, term } = MatchersV3;

const provider = new PactV3({
    consumer: "WebApp",
    provider: "UsersAPI"
});

describe("Users API Consumer", () => {
    it("should return a user by ID", async () => {
        const expectedUser = {
            id: like("usr_abc123"),
            name: like("Alice Johnson"),
            email: like("alice@example.com"),
            createdAt: term({
                generate: "2025-01-15T10:30:00Z",
                matcher: "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z"
            })
        };

        // Set up provider expectation
        provider
            .given("a user exists with ID usr_abc123")
            .uponReceiving("a request for a user")
            .withRequest({
                method: "GET",
                path: "/users/usr_abc123",
                headers: { Accept: "application/json" }
            })
            .willRespondWith({
                status: 200,
                headers: { "Content-Type": "application/json" },
                body: expectedUser
            });

        await provider.executeTest(async (mockServer) => {
            const response = await fetch(`${mockServer.url}/users/usr_abc123`);
            const user = await response.json();

            expect(response.status).toBe(200);
            expect(user.id).toBeDefined();
            expect(user.name).toBeDefined();
        });
    });
});
```

### Provider Side (Pact + FastAPI)

```python
# provider_contract_test.py
from pact import Verifier

def test_provider_meets_contract():
    verifier = Verifier(
        provider="UsersAPI",
        provider_base_url="http://localhost:8000",
    )

    success, logs = verifier.verify_pacts(
        "users-webapp-pact.json",
        provider_states_setup_url="http://localhost:8000/_pact/provider_states",
        verbose=False,
    )

    assert success == 0, f"Contract verification failed: {logs}"
```

### Provider States Setup

```python
from fastapi import FastAPI, APIRouter
from pydantic import BaseModel

app = FastAPI()
router = APIRouter()

# Provider states for Pact testing
provider_states = {}

class ProviderState(BaseModel):
    state: str
    params: dict = {}

@router.post("/_pact/provider_states")
def set_provider_state(body: ProviderState):
    if body.state == "a user exists with ID usr_abc123":
        provider_states["current_user"] = {
            "id": "usr_abc123",
            "name": "Alice Johnson",
            "email": "alice@example.com",
            "created_at": "2025-01-15T10:30:00Z"
        }
    return {"result": "ok"}

@router.get("/users/{user_id}")
def get_user(user_id: str):
    if user_id == "usr_abc123" and "current_user" in provider_states:
        return provider_states["current_user"]
    return {"error": "not found"}, 404

app.include_router(router)
```

### Pact Broker — CI/CD Integration

```yaml
# .github/workflows/pact.yaml
jobs:
  contract-test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: pact_broker
          POSTGRES_USER: pact
          POSTGRES_PASSWORD: pact

    steps:
      - uses: actions/checkout@v3
      - run: npm ci
      - run: npm run test:consumer
      - run: npm run test:provider

      # Publish pacts to broker
      - name: Publish consumer contract
        run: npx pact-broker publish ./pacts \
          --broker-base-url https://pact-broker.example.com \
          --consumer-app-version ${{ github.sha }} \
          --branch ${{ github.ref_name }}

      # Check if safe to deploy
      - name: Can I deploy?
        run: npx pact-broker can-i-deploy \
          --pacticipant WebApp \
          --version ${{ github.sha }} \
          --to-environment production \
          --broker-base-url https://pact-broker.example.com
```

## API Fuzzing

### Fuzzing with Schemathesis

Schemathesis generates test cases from OpenAPI specs and tests for unexpected behavior:

```bash
# Basic fuzzing
st run --checks all https://api.example.com/openapi.yaml

# With custom checks
st run \
  --checks all \
  --validate-schema True \
  --hypothesis-suppress-health-check too_slow \
  --base-url https://api.example.com \
  openapi.yaml
```

### Custom Fuzzer

```python
import requests
import random
import string
from urllib.parse import urljoin

class APIFuzzer:
    def __init__(self, base_url):
        self.base_url = base_url
        self.found_issues = []

    def fuzz_string(self):
        """Generate malicious string inputs"""
        payloads = [
            "' OR '1'='1",
            "<script>alert(1)</script>",
            "../../../etc/passwd",
            "%00",
            "\x00\x00\x00\x00",
            "A" * 10000,  # Buffer overflow
            "{{config}}",
            "${7*7}",
            "<![CDATA[<>]]>",
        ]
        return random.choice(payloads)

    def fuzz_numeric(self):
        """Generate edge case numeric values"""
        payloads = [
            -1, 0, 1,
            2147483647, 2147483648,
            -2147483648, -2147483649,
            1.7976931348623157e308,
            float("inf"), float("nan"),
            -float("inf")
        ]
        return random.choice(payloads)

    def test_endpoint(self, method, path, params=None, body=None):
        url = urljoin(self.base_url, path)
        try:
            response = requests.request(
                method, url,
                params=params,
                json=body,
                timeout=5,
                headers={"Content-Type": "application/json"}
            )

            # Check for concerning responses
            if response.status_code == 500:
                self.found_issues.append({
                    "type": "server_error",
                    "url": url,
                    "input": body or params,
                    "status": 500,
                    "body": response.text[:200]
                })

            # Check for stack traces
            if "Traceback" in response.text or "stack trace" in response.text.lower():
                self.found_issues.append({
                    "type": "stack_trace_exposure",
                    "url": url,
                    "body": response.text[:500]
                })

        except requests.exceptions.Timeout:
            self.found_issues.append({
                "type": "timeout",
                "url": url,
                "input": body or params
            })

    def run(self, endpoints):
        for endpoint in endpoints:
            for _ in range(100):
                if endpoint["method"] == "GET":
                    params = {k: self.fuzz_string() for k in endpoint.get("params", ["q"])}
                    self.test_endpoint("GET", endpoint["path"], params=params)
                elif endpoint["method"] == "POST":
                    body = {k: self.fuzz_string() for k in endpoint.get("body_fields", ["name", "email"])}
                    self.test_endpoint("POST", endpoint["path"], body=body)

        return self.found_issues

# Run fuzzer
fuzzer = APIFuzzer("https://api.example.com")
issues = fuzzer.run([
    {"method": "GET", "path": "/users", "params": ["q", "sort"]},
    {"method": "POST", "path": "/users", "body_fields": ["name", "email", "role"]},
])
```

### Property-Based Testing

```python
from hypothesis import given, strategies as st
from hypothesis.stateful import RuleBasedStateMachine, rule, precondition

# Property-based test for a counter API
@given(
    username=st.text(min_size=1, max_size=64),
    email=st.emails()
)
def test_create_user_properties(username, email):
    response = requests.post("https://api.example.com/users", json={
        "username": username,
        "email": email
    })

    assert response.status_code in (201, 400)  # Valid or invalid

    if response.status_code == 201:
        data = response.json()
        assert "id" in data
        assert data["username"] == username
        assert data["email"] == email
        assert "created_at" in data
        # Idempotent: creating again with same email returns 409
        dup = requests.post("https://api.example.com/users", json={
            "username": username + "_dup",
            "email": email
        })
        assert dup.status_code == 409


# Stateful testing for shopping cart API
class CartStateMachine(RuleBasedStateMachine):
    def __init__(self):
        super().__init__()
        self.session = requests.Session()
        self.cart_id = None
        self.items = {}

    @rule(item=st.text(min_size=1, max_size=20), qty=st.integers(min_value=1, max_value=10))
    def add_item(self, item, qty):
        response = self.session.post(
            f"https://api.example.com/cart/{self.cart_id}/items",
            json={"product_id": item, "quantity": qty}
        )
        assert response.status_code in (200, 400)
        if response.status_code == 200:
            self.items[item] = self.items.get(item, 0) + qty

    @rule(item=st.sampled_from(["item_a", "item_b"]))
    def remove_item(self, item):
        if item in self.items:
            response = self.session.delete(
                f"https://api.example.com/cart/{self.cart_id}/items/{item}"
            )
            assert response.status_code == 200
            del self.items[item]

    @precondition(lambda self: self.cart_id is not None)
    @rule()
    def check_total(self):
        response = self.session.get(f"https://api.example.com/cart/{self.cart_id}")
        assert response.status_code == 200
        cart = response.json()
        expected_count = sum(self.items.values())
        assert cart["item_count"] == expected_count
```

## Integration Testing with Test Containers

```python
# test_integration.py
import pytest
from testcontainers.postgres import PostgresContainer
from testcontainers.redis import RedisContainer
import psycopg2
import redis

@pytest.fixture(scope="module")
def postgres():
    with PostgresContainer("postgres:15") as postgres:
        conn = psycopg2.connect(
            host=postgres.get_container_host_ip(),
            port=postgres.get_exposed_port(5432),
            user=postgres.USER,
            password=postgres.PASSWORD,
            dbname=postgres.DBNAME
        )
        yield conn
        conn.close()

@pytest.fixture(scope="module")
def redis_client():
    with RedisContainer("redis:7") as redis_container:
        client = redis.Redis(
            host=redis_container.get_container_host_ip(),
            port=redis_container.get_exposed_port(6379)
        )
        yield client

def test_user_creation_integration(postgres, redis_client):
    cur = postgres.cursor()
    cur.execute("""
        INSERT INTO users (id, name, email)
        VALUES (%s, %s, %s)
    """, ("usr_test", "Test User", "test@example.com"))
    postgres.commit()

    # Verify in Redis cache
    redis_client.set("user:usr_test", '{"id": "usr_test", "name": "Test User"}')
    cached = redis_client.get("user:usr_test")
    assert cached is not None

    # Test API with real dependencies
    response = requests.get("http://localhost:8000/users/usr_test")
    assert response.status_code == 200
    assert response.json()["name"] == "Test User"
```

### Docker Compose for Integration Tests

```yaml
# docker-compose.test.yaml
services:
  app:
    build: .
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
      kafka:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql://user:pass@postgres:5432/testdb
      REDIS_URL: redis://redis:6379
      KAFKA_BROKER: kafka:9092

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: testdb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d testdb"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7

  kafka:
    image: confluentinc/cp-kafka:latest
    depends_on:
      - zookeeper
    healthcheck:
      test: ["CMD", "kafka-broker-api-versions.sh", "--bootstrap-server", "localhost:9092"]

  zookeeper:
    image: confluentinc/cp-zookeeper:latest
```

```bash
# Run integration tests
docker-compose -f docker-compose.test.yaml up --abort-on-container-exit --exit-code-from app
```

## API Performance Testing

### k6 Script

```javascript
import http from "k6/http";
import { check, sleep } from "k6";
import { Rate, Trend } from "k6/metrics";

const errorRate = new Rate("errors");
const responseTime = new Trend("response_time");

export const options = {
    stages: [
        { duration: "2m", target: 50 },   // Ramp up to 50 users
        { duration: "5m", target: 50 },   // Stay at 50
        { duration: "2m", target: 200 },  // Ramp up to 200
        { duration: "5m", target: 200 },  // Stay at 200
        { duration: "2m", target: 0 },    // Ramp down
    ],
    thresholds: {
        http_req_duration: ["p(95)<500", "p(99)<1000"],
        errors: ["rate<0.01"],
        http_req_failed: ["rate<0.01"],
    },
};

const BASE_URL = __ENV.API_URL || "https://api.example.com";

export default function () {
    const params = {
        headers: {
            Authorization: `Bearer ${__ENV.API_TOKEN}`,
            "Content-Type": "application/json",
        },
        timeout: "10s",
    };

    // GET users
    const getUsers = http.get(`${BASE_URL}/users?limit=20`, params);
    check(getUsers, {
        "GET /users status is 200": (r) => r.status === 200,
        "GET /users response time < 500ms": (r) => r.timings.duration < 500,
    });
    responseTime.add(getUsers.timings.duration);
    errorRate.add(getUsers.status !== 200);
    sleep(1);

    // POST create user
    const payload = JSON.stringify({
        name: `Test User ${Date.now()}`,
        email: `test${Date.now()}@example.com`,
    });
    const createUser = http.post(`${BASE_URL}/users`, payload, params);
    check(createUser, {
        "POST /users status is 201": (r) => r.status === 201,
        "POST /users has id": (r) => JSON.parse(r.body).id !== undefined,
    });
    sleep(0.5);
}
```

```bash
# Run k6 test
k6 run --vus 10 --duration 30s perf-test.js

# Run with environment variables
API_URL=https://staging.example.com API_TOKEN=abc123 k6 run perf-test.js
```

### hey / wrk

```bash
# Simple load test with hey
hey -n 10000 -c 100 \
  -H "Authorization: Bearer token123" \
  -H "Content-Type: application/json" \
  https://api.example.com/users

# With wrk
wrk -t12 -c400 -d30s \
  -H "Authorization: Bearer token123" \
  https://api.example.com/users
```

## Postman / Insomnia Collections

### Postman Collection (JSON)

```json
{
  "info": {
    "name": "Users API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    { "key": "base_url", "value": "https://api.example.com" },
    { "key": "token", "value": "" }
  ],
  "auth": {
    "type": "bearer",
    "bearer": [{ "key": "token", "value": "{{token}}", "type": "string" }]
  },
  "item": [
    {
      "name": "List Users",
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.test('Status is 200', () => { pm.response.to.have.status(200); });",
              "pm.test('Returns array', () => { pm.expect(pm.response.json().data).to.be.an('array'); });",
              "pm.test('Response time < 500ms', () => { pm.expect(pm.response.responseTime).to.be.below(500); });"
            ]
          }
        }
      ],
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{base_url}}/users?limit=20",
          "query": [
            { "key": "limit", "value": "20" }
          ]
        }
      }
    },
    {
      "name": "Create User",
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.test('Status is 201', () => { pm.response.to.have.status(201); });",
              "pm.test('Has user ID', () => { pm.expect(pm.response.json().id).to.not.be.empty; });"
            ]
          }
        }
      ],
      "request": {
        "method": "POST",
        "header": [
          { "key": "Content-Type", "value": "application/json" }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"name\": \"Alice Johnson\",\n  \"email\": \"alice@example.com\"\n}"
        },
        "url": {
          "raw": "{{base_url}}/users"
        }
      }
    }
  ]
}
```

### Newman (Postman CLI Runner)

```bash
# Run Postman collection in CI
newman run Users-API.postman_collection.json \
  --env-var "base_url=https://staging.example.com" \
  --env-var "token=${API_TOKEN}" \
  --reporters cli,junit \
  --reporter-junit-export results.xml

# With HTML reporter
newman run collection.json \
  -e environment.json \
  -r htmlextra \
  --reporter-htmlextra-export ./reports/report.html
```

## API Monitoring

```javascript
// monitor.js — Continuous production monitoring
import http from "k6/http";
import { check, sleep } from "k6";
import { Rate } from "k6/metrics";

const failureRate = new Rate("monitor_failures");

export const options = {
    vus: 1,
    duration: "1h",
    thresholds: {
        monitor_failures: ["rate<0.001"], // <0.1% failure rate
    },
};

const ENDPOINTS = [
    { method: "GET", path: "/health", expected: 200 },
    { method: "GET", path: "/users?limit=1", expected: 200 },
    { method: "GET", path: "/users/usr_test", expected: 200 },
    { method: "POST", path: "/users", expected: 400 }, // Missing body
];

export default function () {
    for (const endpoint of ENDPOINTS) {
        const start = Date.now();
        const res = http.request(endpoint.method, `${BASE_URL}${endpoint.path}`, null, {
            headers: { Authorization: `Bearer ${API_TOKEN}` },
            timeout: "5s",
        });
        const latency = Date.now() - start;

        const success = check(res, {
            [`${endpoint.method} ${endpoint.path} status`]: (r) => r.status === endpoint.expected,
            [`${endpoint.method} ${endpoint.path} latency`]: (r) => latency < 2000,
        });

        failureRate.add(!success);

        if (!success) {
            // Alert immediately
            sendAlert({
                endpoint: `${endpoint.method} ${endpoint.path}`,
                expected: endpoint.expected,
                got: res.status,
                latency,
                timestamp: new Date().toISOString()
            });
        }

        sleep(30); // Check every 30 seconds
    }
}
```

## Best Practices

- **Test the contract, not the implementation** — focus on what the API does, not how
- **Use consumer-driven contracts** — let consumers define their expectations
- **Automate in CI** — run contract tests on every PR
- **Include negative tests** — test with invalid inputs, missing fields, wrong types
- **Test idempotency** — same request twice should give same result
- **Test error responses** — verify error format, codes, and messages
- **Use realistic data** — production-like volumes, distributions, and formats
- **Monitor in production** — synthetic health checks and real user monitoring
- **Version your tests** — keep tests in sync with API versions
- **Fuzz in staging** — run fuzz tests against a non-production environment

## Interview Questions

1. What is contract testing and how does it differ from integration testing?
2. How does Pact consumer-driven contract testing work? Explain the workflow.
3. What is API fuzzing? How does it find vulnerabilities that unit tests miss?
4. Explain property-based testing with an example for an API.
5. How do test containers help with integration testing? What problems do they solve?
6. Design a performance test for a payment API that must handle 1000 TPS.
7. How do you test idempotency of an API endpoint?
8. What metrics should you monitor for API health in production?
9. How do you validate that an API is backward compatible in CI?
10. Compare Postman/Newman vs k6 vs custom testing frameworks for API testing.

## Real Company Usage

| Company | Testing Approach |
|---------|-----------------|
| **Spotify** | Contract testing with Pact; 500+ microservices with CI/CD verification |
| **Netflix** | Chaos testing (Chaos Monkey); property-based tests; canary analysis |
| **Uber** | Contract testing for service mesh; property-based tests for fare calculation |
| **Twilio** | Extensive fuzz testing; Postman collections for developer docs |
| **Stripe** | Idempotency testing at scale; automated regression on every change |
| **GitHub** | Integration tests with test containers; API monitoring with synthetic checks |
| **Shopify** | Pact contract testing between services; load testing with k6 |
| **Google** | Hybrid approach: contract tests, fuzzing (OSS-fuzz), performance benchmarks |
