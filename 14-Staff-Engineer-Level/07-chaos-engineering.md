# Chaos Engineering

## Definition
Chaos engineering is the discipline of experimenting on a system to build confidence in its capability to withstand turbulent conditions in production.

## Principles

| Principle | Description |
|-----------|-------------|
| **Start with steady state** | Define normal system behavior |
| **Hypothesize** | "If X fails, the system still works" |
| **Run experiments** | Inject real failures |
| **Minimize blast radius** | Start small, expand gradually |
| **Automate** | Run continuously |

## Tools

| Tool | Provider | Type |
|------|----------|------|
| **Chaos Monkey** | Netflix | Random instance termination |
| **Litmus** | CNCF | Kubernetes chaos |
| **Gremlin** | Gremlin Inc | Managed chaos engineering |
| **Chaos Mesh** | PingCAP | Kubernetes chaos platform |
| **AWS Fault Injection Simulator** | AWS | AWS resource chaos |

## Example Experiments

| Experiment | Hypothesis | Duration |
|------------|------------|----------|
| Kill 1 of 5 instances | Traffic redirects to remaining | 5 min |
| Increase latency by 200ms | P95 stays under 500ms | 10 min |
| Block database port | Cache serves stale data | 5 min |
| Run out of disk | Log rotation works | 5 min |
| DNS failure | Fallback DNS works | 10 min |

## Game Day Process

```
1. Plan: Define scenario, hypothesis, metrics
2. Prepare: Alert stakeholders, pause automation
3. Execute: Run the experiment
4. Observe: Monitor metrics, observe behavior
5. Debrief: What worked? What broke? What to fix?
6. Follow-up: Create tickets for issues found
```

## Interview Questions
1. How does chaos engineering differ from traditional testing?
2. Design a chaos experiment for a critical payment service
3. How do you ensure chaos experiments don't cause real incidents?
4. What's the first chaos experiment you'd run on a new system?
5. How do you build a culture of chaos engineering?
