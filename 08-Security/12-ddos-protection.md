# DDoS Protection

## Definition
A Distributed Denial-of-Service (DDoS) attack overwhelms a target with traffic from multiple sources, making it unavailable to legitimate users.

## Attack Types

| Layer | Attack Type | Example |
|-------|-------------|---------|
| L3/L4 | Volumetric | UDP flood, SYN flood, ICMP flood |
| L7 | Application | HTTP flood, Slowloris, DNS query flood |
| Protocol | State-exhaustion | TCP state table exhaustion |

## Defense Strategies

```
1. Absorb (large capacity)
2. Detect (anomaly detection)
3. Filter (WAF, rate limiting)
4. Scrub (traffic scrubbing centers)
5. Migrate (change IP, use CDN)
```

| Defense | Provider | Method |
|---------|----------|--------|
| AWS Shield | AWS | Automatic L3/L4 mitigation |
| Cloudflare | Cloudflare | Anycast network, rate limiting |
| Google Cloud Armor | GCP | WAF + rate limiting |
| Azure DDoS Protection | Azure | Automatic L3/L4 + L7 |

## Interview Questions
1. How does a DDoS attack differ from a DoS attack?
2. How does Cloudflare's anycast network absorb DDoS traffic?
3. What's the difference between L3, L4, and L7 DDoS attacks?
4. How do you design a DDoS-resilient architecture?
5. What is a scrubbing center and how does it work?
