# Facebook 2021 Outage

```mermaid
timeline
    title Facebook 2021 Outage – BGP Cascade
    15:40 UTC : BGP routes withdrawn for Facebook prefixes
    15:45 : DNS resolvers worldwide can&#39;t resolve facebook.com
    15:50 : Internal traffic to data centers fails
    16:00 : Engineers locked out (VPN, DNS broken)
    16:30 : Physical data center access required
    21:00 : BGP routes restored
    22:45 : Full recovery
```

## Timeline (Oct 4, 2021)
- **15:40 UTC**: BGP routes withdrawn for Facebook prefixes
- **15:45**: DNS resolvers worldwide can't resolve facebook.com
- **15:50**: Internal traffic to Facebook data centers fails
- **16:00**: Engineers can't access systems (VPN, DNS broken)
- **16:30**: Physical data center access required
- **21:00**: BGP routes restored
- **22:45**: Full recovery

## Root Cause
A routine BGP configuration update incorrectly withdrew all IP prefixes for Facebook's DNS servers. Since Facebook's infrastructure uses self-managed DNS, this took down DNS resolution for all Facebook properties — including the internal tools needed to fix the problem.

## Cascading Failure
```
BGP config error
    │
    ▼
DNS servers unreachable
    │
    ▼
facebook.com, instagram.com, whatsapp.com unresolvable
    │
    ▼
Internal tools (VPN, monitoring, admin panels) also down
    │
    ▼
Can't fix remotely — need physical access
    │
    ▼
6+ hours of global outage
```

## Impact
- 3.5B users affected globally
- Estimated $100M+ revenue loss
- Facebook stock dropped ~5%
- 6+ hour full outage
- Internal communication down

## Lessons Learned
1. **Defense in depth**: Never depend on your own external services for internal access
2. **BGP safeguards**: Implement route validation, max-prefix limits, change review
3. **Out-of-band access**: Maintain emergency access (dedicated VPN, backup DNS)
4. **Gradual rollout**: BGP updates should be staged, not applied globally
5. **Testing**: Test infrastructure changes in isolated environments first

## Interview Questions
1. How could Facebook have prevented this outage?
2. What is BGP and why does a configuration error cause such widespread impact?
3. Design an out-of-band access system for critical infrastructure
4. How would you design a BGP update process to prevent similar incidents?
5. What monitoring would detect this issue faster?
