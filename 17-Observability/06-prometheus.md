# Prometheus

## Architecture

```
Service    Service    Service
    │          │          │
    ├───>──┐   │   ┌──<──┤
           ▼   ▼   ▼
       ┌─────────────┐
       │  Prometheus  │
       │  Server      │
       └──────┬──────┘
              │
         ┌────▼────┐
         │Alert    │
         │Manager  │
         └────┬────┘
              │
         ┌────▼────┐
         │PagerDuty│
         └─────────┘
```

```mermaid
sequenceDiagram
    participant P as Prometheus Server
    participant SD as Service Discovery
    participant S1 as Service A
    participant S2 as Service B
    participant AM as Alertmanager
    P->>SD: Discover scrape targets
    SD->>P: Endpoint list
    loop Scrape interval (default 15s)
        P->>S1: GET /metrics
        S1-->>P: Metrics response
        P->>S2: GET /metrics
        S2-->>P: Metrics response
    end
    P->>P: Evaluate recording & alerting rules
    P->>AM: Push firing alerts
    AM->>AM: Dedup, group, silence
    AM->>PagerDuty: Notify on-call
```

## Key Features
- **Pull-based metrics** — Scrapes targets at intervals
- **Multi-dimensional** — Labels enable flexible queries
- **Powerful query language** — PromQL
- **Built-in alerting** — Alertmanager
- **Service discovery** — Kubernetes, Consul, file-based

## PromQL Examples

```promql
# CPU usage by service
avg(rate(node_cpu_seconds_total{mode="user"}[5m])) by (service)

# Error ratio
sum(rate(http_requests_total{status=~"5.."}[5m])) 
  / sum(rate(http_requests_total[5m])) * 100

# P99 latency
histogram_quantile(0.99, 
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))
```

## Interview Questions
1. How does Prometheus's pull model differ from push-based monitoring?
2. How does Prometheus service discovery work in Kubernetes?
3. What are the limitations of Prometheus at scale?
4. How does Prometheus's Alertmanager handle deduplication?
5. Design a Prometheus-based monitoring solution for 1000 microservices
