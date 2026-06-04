# Architecture Reviews

## Purpose
- Catch issues early before they're expensive to fix
- Share knowledge and patterns across teams
- Ensure consistency with organizational standards
- Challenge assumptions and validate tradeoffs

## Review Checklist

### Requirements
☐ Functional requirements are complete
☐ Non-functional requirements defined (latency, availability, durability)
☐ Scale assumptions are realistic

### Design
☐ Architecture diagram is clear
☐ Data flow is documented (happy path + error paths)
☐ State management is described
☐ Security considerations addressed

### Tradeoffs
☐ Alternatives considered and documented
☐ Why this approach over others?
☐ What was sacrificed?

### Operations
☐ Monitoring and alerting plan
☐ Deployment strategy (canary, blue-green)
☐ Rollback plan
☐ Runbook for common failures

## Running a Review

```
1. Author sends RFC 1 week in advance
2. Reviewers read and comment async
3. Meeting for discussion (not first read)
4. Capture decisions and action items
5. Follow up on unresolved issues
```

## Interview Questions
1. How do you conduct an architecture review?
2. What do you look for when reviewing a system design?
3. How do you handle disagreements in architecture reviews?
4. What's the worst architecture decision you've caught in review?
5. How do you balance speed vs rigor in reviews?
