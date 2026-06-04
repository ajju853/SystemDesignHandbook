# AWS Kinesis Outage (2020)

## Event
During the COVID-19 pandemic, AWS Kinesis experienced severe throttling across multiple regions. The surge in streaming data (as businesses shifted to remote work) exceeded Kinesis capacity, causing widespread failures for customers who depended on Kinesis for real-time data pipelines.

## Timeline
- **March 2020**: COVID lockdowns cause massive spike in streaming data
- **Weeks of throttling**: Kinesis customers hit service limits repeatedly
- **Cascading failures**: Downstream consumers (Lambda, Kinesis Analytics) failed as backlogs grew
- **Slow recovery**: Throttling persisted as backlogs took hours to drain

## Root Cause
- Unexpected traffic pattern shift (not just growth — a spike)
- Kinesis throttling limits (provisioned throughput per shard)
- Rate limiting didn't differentiate between critical vs non-critical data
- Recovery slow because drained capacity got consumed by retries

## Architecture Lessons

```
Problem: Kinesis throttling → downstream failures → retries → more throttling
How to prevent:

1. Auto-scaling for shards
   - Monitor incoming throughput vs provisioned
   - Auto-split hot shards
   - Pre-warm for known spikes

2. Graceful degradation hierarchy
   - Tier 1: Customer transactions (must process)
   - Tier 2: Analytics events (can batch)
   - Tier 3: Debug logs (can drop)

3. Back-pressure handling
   - Downstream services signal when overloaded
   - Kinesis throttles at the source, not at the consumer

4. Circuit breakers
   - If consumer is failing → stop reading from shard
   - Implement exponential backoff
   - Dead-letter queue for failed records
```

## Lessons Learned

1. **Plan for spikes** — Auto-scale capacity; don't rely on static provisioning
2. **Graceful degradation** — Drop non-critical data first; protect the pipeline
3. **Circuit breakers** — Isolate failures between services; prevent cascading
4. **Backlog recovery** — Have a replay strategy; don't retry all at once
5. **Monitoring** — Track shard utilization, consumer lag; alert before throttling

## Interview Questions

1. How would you design a streaming pipeline that degrades gracefully?
2. What capacity planning strategies prevent throttling?
3. How do you recover from a massive streaming backlog?
4. How would you implement back-pressure in a Kinesis-based system?
5. Design a monitoring system that alerts before shard throttling occurs
