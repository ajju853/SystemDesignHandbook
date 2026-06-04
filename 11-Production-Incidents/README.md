# 11 — Production Incidents

> Learn from real failures. Every incident is a lesson in system design.

## Topics

| # | Incident | Key Lesson |
|---|----------|------------|
| 1 | [Facebook 2021 Outage](01-facebook-2021.md) | BGP withdrawal, cascading DNS failure |
| 2 | [AWS Kinesis Outage](02-aws-kinesis.md) | Throttling, rate limiting cascade |
| 3 | [Google Cloud Outage](03-google-cloud.md) | Configuration error, global impact |
| 4 | [Cloudflare Outage](04-cloudflare.md) | Resource exhaustion, bad deploy |
| 5 | [GitHub Outage](05-github-outage.md) | Database degradation, replication lag |
| 6 | [Fastly CDN Outage](06-fastly-outage.md) | Software bug, configuration edge case |
| 7 | [GitLab Backup Failure](07-gitlab-backup.md) | No backup validation, full data loss |

## Format

Every incident includes:
- **Timeline**: What happened, when
- **Root Cause**: The underlying failure
- **Impact**: Users, revenue, reputation affected
- **Detection**: How it was discovered
- **Resolution**: How it was fixed
- **Lessons Learned**: Prevention and improvements

---

Previous: [10 — Open Source Architectures](../10-Open-Source-Architectures/README.md)
Next: [12 — Hands-On Projects](../12-Hands-On-Projects/README.md)
