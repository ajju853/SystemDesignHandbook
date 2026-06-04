# GitLab Backup Failure (2017)

## Event
On January 31, 2017, GitLab experienced a catastrophic data loss incident. A systems engineer accidentally deleted the production database during a maintenance operation, resulting in the loss of 300GB of data (6 hours of database changes).

## Timeline
- **04:40 UTC**: Engineer performing database replication maintenance
- **04:45 UTC**: Engineer accidentally runs `rm -rf` on the wrong server
- **04:46 UTC**: Production database deleted — immediately recognized
- **05:00 UTC**: Backup restoration attempted from 5 backup mechanisms
- **05:30 UTC**: ALL 5 backup mechanisms failed or were insufficient
- **06:00 UTC**: GitLab goes into read-only mode
- **11:00 UTC**: Database partially restored from a 6-hour-old snapshot
- **Ongoing**: 6 hours of data (issues, merge requests, comments) permanently lost

## The Five Failed Backups

```
1. pg_dump (daily)
   Status: FAILED
   Reason: Hadn't run in 6 hours — 6 hours of data not captured
   
2. S3 Snapshots (every 24 hours)
   Status: FAILED  
   Reason: Snapshots were being taken but replication hadn't completed
   
3. Database Replication (streaming)
   Status: FAILED
   Reason: Replica was behind — same 5+ hours of data missing
   
4. LVM Snapshots (hourly)
   Status: FAILED
   Reason: LVM snapshots weren't configured for this database
   
5. Manual Backup (engineer's local copy)
   Status: FAILED
   Reason: Backup script existed but hadn't been run/tested
   
Bottom line: No backup mechanism was verified end-to-end.
```

## Lessons Learned (The "5 Backup Rule")

| Lesson | Implementation |
|--------|---------------|
| **Verify backups** | Automated restore testing — weekly |
| **Least privilege** | No production write access without approval |
| **Destructive action safeguards** | `rm -rf` requires `\c` confirmation on prod |
| **Separation of environments** | Different colored terminals, distinct server names |
| **Automated recovery testing** | Scheduled restore drills with measured RTO/RPO |
| **Immutable infrastructure** | Don't SSH into prod — deploy code, don't delete |

## Backup Best Practices (Post-Incident)

```
3-2-1 Rule:
- 3 copies of data
- 2 different storage types
- 1 offsite copy

GitLab's current approach:
1. PostgreSQL streaming replication (real-time, hot standby)
2. pg_dump to S3 (hourly, encrypted)
3. WAL archive to GCS (continuous, 30-day retention)
4. Automated restore test (weekly, full recovery)
5. Point-in-time recovery (restore to any second)

Access controls:
- No sudo access to production (bastion host + approved commands)
- All destructive operations require 2-person approval
- `rm -rf` is aliased to `safe-rm` on all production servers
- Immutable deployments: never modify running infrastructure
```

## Interview Questions

1. How would you design a backup strategy that's disaster-proof?
2. How do you prevent accidental deletion of production data?
3. What processes ensure backups are actually restorable?
4. Design a system that automates backup verification
5. How does the 3-2-1 backup rule apply to cloud infrastructure?
