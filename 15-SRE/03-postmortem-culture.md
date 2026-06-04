# Postmortem Culture

## What is it?

A postmortem is a written record of an incident that details what happened, why it happened, what went well, what went wrong, and what actions will prevent recurrence. **Blameless postmortems** are the cornerstone of SRE culture — they assume everyone acted with good intent and focus on systemic fixes rather than individual mistakes.

## Why it matters

- Blame destroys learning — people hide errors, stop reporting, and the same incidents recur
- Postmortems turn incidents into improvement opportunities
- Written postmortems are searchable knowledge bases for future responders
- Google's data shows most outages are caused by system complexity, not individual negligence

## Implementation

### Google's Postmortem Philosophy

> "The goal of a postmortem is not to assign blame. The goal is to learn from what happened and prevent it from happening again."

— Google SRE Book

### Key Principles

| Principle | Practice |
|-----------|----------|
| **Assume good intent** | No one comes to work to break things |
| **Fix the system** | Ask "what in the process allowed this to happen?" |
| **Psychological safety** | People must feel safe to admit mistakes |
| **Share publicly** | Postmortems are shared org-wide (with redaction if needed) |

### 5 Whys — Root Cause Analysis

The **5 Whys** technique iteratively asks "why" to drill from symptom to root cause:

```
Problem: Production database ran out of storage.

Why? → Automated cleanup job didn't run.
Why? → Cron entry was missing after the last server migration.
Why? → The migration playbook didn't include cron verification.
Why? → Playbook was written 2 years ago and never reviewed.
Why? → No process for periodic playbook review.
→ Root cause: Missing review cycle for operational playbooks.
```

### Postmortem Timeline Reconstruction

| Time (UTC) | Event |
|------------|-------|
| 14:02 | PagerDuty alert: API error rate > 5% |
| 14:05 | Engineer acknowledges, declares SEV-2 |
| 14:08 | Rollback of deploy v3.2.1 initiated |
| 14:12 | Rollback complete; error rate dropping |
| 14:20 | Error rate back to baseline; incident mitigated |
| 16:00 | Post-incident review meeting scheduled |

### Example Postmortem Template

```markdown
# Postmortem: [Incident Title]

## Summary
- **Date**: 2026-06-04
- **Duration**: 18 minutes (14:02–14:20 UTC)
- **Severity**: SEV-2
- **Services affected**: User API, Search

## Timeline
| Time | Event |
|------|-------|
| 14:02 | Alert fired |
| 14:05 | IC assigned |
| 14:08 | Decision to rollback |
| 14:12 | Rollback complete |
| 14:20 | All clear |

## Root Cause
A missing null check in `UserSearchService.java` (PR #4289) caused 
a NullPointerException on accounts without a profile picture.

## Contributing Factors
- PR #4289 had no unit test for null profile path
- The reviewer approved without noticing the missing edge case
- The staging environment had no users without profile pictures

## What Went Well
- Rollback completed in under 10 minutes
- Communication was clear and timely
- Dashboard made error rate spike immediately visible

## What Went Wrong
- No unit test coverage for edge case
- Staging data did not mirror production

## Action Items
- [ ] Add null check and unit test (owner: @alice, due: 2026-06-06)
- [ ] Audit staging data for production parity (owner: @bob, due: 2026-06-11)
- [ ] Add PR checklist item: "Edge cases covered?" (owner: @carol, due: 2026-06-04)

## Lessons Learned
- Always include null/empty edge cases in API PRs
- Alert on NPE rate, not just error rate
```

## Best Practices

- **Postmortem within 48 hours** of incident end — memory fades fast
- Every action item must have an owner and a due date
- Track action items to completion — use a ticketing system (Jira, Linear)
- Hold a **postmortem readout** meeting (30 min)
- Celebrate postmortems — the more postmortems, the more learning culture
- **No blame language**: replace "Bob deployed broken code" with "The deploy process did not enforce mandatory code review"

## Interview Questions

1. What is a blameless postmortem and why is it important for a reliability culture?
2. Walk me through the 5 Whys analysis for a real or hypothetical outage.
3. How do you ensure postmortem action items actually get completed?
4. What would you do if a team member resisted writing postmortems?
5. How do you balance sharing postmortems broadly while being sensitive about mistakes?
6. What is the difference between contributing factors and root cause?

## Cross-Links

- [18-Case-Studies: GitHub Outage](../18-Case-Studies/05-github-outage.md) — Example of postmortem analysis
- [18-Case-Studies: GitLab Backup](../18-Case-Studies/07-gitlab-backup.md) — Incident with deep postmortem
- [14-DevOps: Monitoring & Logging](../14-DevOps/08-monitoring-logging.md) — Logging for timeline reconstruction
- [21-Staff-Engineer: Chaos Engineering](../21-Staff-Engineer/07-chaos-engineering.md) — Proactive reliability testing
