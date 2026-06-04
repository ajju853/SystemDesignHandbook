# Toil Reduction

## What is it?

**Toil** is operational work that is manual, repetitive, automatable, non-value-added, and scales linearly with growth. Google's SRE model defines toil as work that:

1. Is **manual** — requires human intervention
2. Is **repetitive** — done the same way every time
3. Is **automatable** — could be replaced by code
4. Has **no enduring value** — doesn't improve the service
5. **Scales linearly** — adding more users adds proportionally more work

## Why it matters

- Toil is the enemy of reliability — it distracts from engineering work that prevents incidents
- Google caps toil at **50% of SRE time**; the other 50% must be engineering projects
- High toil leads to burnout, pager fatigue, and turnover
- Every manual step is a potential failure point and delay in incident response

## Implementation

### Measuring Toil

Track toil with a simple weekly survey or time-tracking tool:

| Activity | Hours/Week | Type |
|----------|------------|------|
| Responding to user ticket "my report is slow" | 4 | Toil |
| Restarting failed batch jobs | 3 | Toil |
| Building a new Grafana dashboard | 2 | Engineering |
| Automating certificate rotation | 5 | Engineering |
| Firefighting production page | 3 | Toil |
| Writing runbook | 1 | Engineering |

**Goal**: Toil < 50% of total SRE time (typically < 20 hours/week for a full-time SRE).

### Toil Elimination Strategies

| Strategy | Example |
|----------|---------|
| **Automate the task** | Write a script to rotate TLS certificates |
| **Eliminate the need** | Make config self-healing instead of manually fixing |
| **Give it to the user** | Self-service portal for common requests |
| **Redesign** | Re-architect to remove the manual step entirely |
| **Accept it** | Some toil is unavoidable (e.g., hardware repair) |

### Automation Opportunities

| Common Toil | Automation Solution |
|-------------|---------------------|
| Restarting crashed services | Systemd, Kubernetes auto-restart |
| Deploying code | CI/CD pipeline |
| Rotating certificates | cert-manager, ACME protocol |
| Patching servers | Ansible, patch management |
| Creating users | IAM, SSO integration |
| Restarting DB replicas | auto-failover, managed DB |
| Answering "what's the status?" | Status page, dashboard |
| Provisioning resources | Terraform, CloudFormation |

### Automation Maturity Model

| Level | Description | Example |
|-------|-------------|---------|
| **L0** | Manual, no documentation | Restart server via SSH |
| **L1** | Manual with runbook | Runbook describes steps |
| **L2** | Scripted | Shell script automates |
| **L3** | Scheduled / event-driven | Cron job runs script |
| **L4** | Self-healing | System detects and fixes automatically |
| **L5** | Predictive | Prevents the issue before it occurs |

### Google's Toil Budget

> "If an SRE team spends more than 50% of their time on operational work, they will not have time to build the automation and tools needed to keep up with growth. The team will end up with a growing operational burden and ever-decreasing reliability."

— Google SRE Book

## Best Practices

- **Track toil weekly** — what gets measured gets managed
- **Create a toil budget** — if a team exceeds 50%, pause new feature work until toil is reduced
- Each sprint should have a **"toil reduction"** user story
- Use **automation sprints** — dedicate a full sprint to automating the top 3 toil items
- Reward teams for reducing toil, not just for fighting fires
- If a task requires manual effort more than twice, **automate it**

### Identifying Toil — The "Three Times" Rule

If you've done a task three times manually:
1. Document it (runbook)
2. The third time, open a ticket to automate it
3. The fourth time, the automation should exist

## Interview Questions

1. What is toil and how is it different from "engineering work"?
2. How does Google enforce the 50% toil budget?
3. Give me an example of a toil reduction project you'd prioritize.
4. How do you measure toil across a team of SREs?
5. What would you automate first in a team that spends 80% of time on operational work?
6. When is it acceptable to leave toil un-automated?

## Cross-Links

- [14-DevOps: Ansible](../14-DevOps/06-ansible.md) — Automation of operational tasks
- [14-DevOps: GitHub Actions](../14-DevOps/02-github-actions.md) — CI/CD automation
- [14-DevOps: CI/CD Pipeline Design](../14-DevOps/07-ci-cd-pipeline-design.md) — Pipeline automation
- [17-Observability: Monitoring](../17-Observability/02-monitoring.md) — Reducing toil with dashboards
