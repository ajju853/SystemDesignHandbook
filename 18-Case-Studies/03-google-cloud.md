# Google Cloud Outage (2019)

## Event
On April 2, 2019, Google Cloud Platform experienced a multi-hour outage affecting GCP services globally. Services impacted included GKE (Kubernetes Engine), Cloud Functions, Cloud Storage, and App Engine. The outage started in us-central1 and cascaded to other regions.

## Timeline
- **14:09 UTC**: Mistyped configuration flag deployed during routine maintenance
- **14:15 UTC**: GKE control plane becomes unresponsive in us-central1
- **14:30 UTC**: Cloud Functions and Cloud Storage start failing
- **15:00 UTC**: Impact spreads to europe-west1 and asia-east1
- **17:00 UTC**: Root cause identified, configuration reverted
- **19:30 UTC**: Services fully recovered

## Root Cause
A configuration change during routine maintenance contained a typo in a flag that controlled how GCP's control plane nodes communicated. The mistyped flag caused:

1. Control plane nodes couldn't establish mutual TLS connections
2. Health checks failed, triggering automated remediation
3. Remediation restarted nodes (which loaded the same bad config)
4. Repeat cycle made recovery impossible without manual intervention
5. Cross-region impact because global control plane shared the config

## Lessons Learned

```
1. Configuration validation
   - Automated syntax checking (JSON/YAML schema validation)
   - Semantic validation (test config on non-production)
   - Dry-run mode: "config would cause X effect"

2. Progressive rollouts
   - Never change all regions at once (staged by region)
   - Canary: 1% → 10% → 50% → 100%
   - Auto-rollback if error rate increases

3. Multi-region isolation
   - Control plane config should be region-scoped
   - A failure in us-central1 shouldn't affect europe-west1
   - Global config with regional overrides

4. Remediation safety
   - Automated remediation must check: "is config valid?"
   - Remediation shouldn't make the problem worse
   - Cap remediation attempts per time window
```

## Interview Questions

1. How do you validate infrastructure configuration changes?
2. How would you design a multi-region system that's isolated?
3. What monitoring detects configuration-related issues?
4. How do you implement progressive rollouts for infrastructure changes?
5. Design an automated remediation system that doesn't make outages worse
