# Cloud Armor

## What is it?
Cloud Armor is Google Cloud's Web Application and API Protection (WAAP) service, providing WAF capabilities, DDoS defense, and security policies for HTTP(S) Load Balancers.

## Why it was created
Web applications face constant threats: SQL injection, XSS, DDoS attacks, and automated bots. Cloud Armor provides Google-grade threat intelligence and WAF capabilities integrated directly with GCP load balancers.

## When should you use it
- Protecting HTTP(S) applications behind Cloud Load Balancing
- Blocking OWASP Top 10 web application vulnerabilities
- Mitigating DDoS attacks (L3/L7)
- Geo-restricting access to applications
- Rate limiting to prevent API abuse
- IP allowlist/denylist for trusted or blocked sources
- Compliance with PCI-DSS, HIPAA, SOC 2 (WAF requirement)

## Architecture

```mermaid
graph TB
    subgraph Internet
        USR[Users]
        ATK[Attackers]
        BOT[Bots / Scrapers]
    end
    subgraph Cloud Armor
        SP[Security Policy]
        OWASP[OWASP Rules]
        RL[Rate Limiting]
        GEO[Geo-Based Rules]
        IP[IP Allow/Deny Lists]
        PD[Pre-configured WAF Rules]
    end
    subgraph GCP
        LB[HTTPS Load Balancer]
        BE[Backend (GCS/GKE/CR/VM)]
    end
    USR --> LB
    ATK --> LB
    BOT --> LB
    LB --> SP
    SP --> OWASP
    SP --> RL
    SP --> GEO
    SP --> IP
    SP --> PD
    OWASP --> BE
    RL --> BE
```

## Security Policies
- Set of rules applied to backend services or backend buckets
- Each rule has: priority, action (allow/deny), condition (match expression), description
- Default rule at lowest priority (deny or allow all)
- Rules evaluated in priority order (first match wins)
- Can be attached to: external HTTP(S) LB, external TCP/SSL LB, Cloud CDN backends

## OWASP Rules (ModSecurity Core Rule Set)
- Pre-configured WAF rules based on ModSecurity CRS v3.x
- Categories:
  - **SQLi**: Block SQL injection attempts (`evaluatePreconfiguredExpr('sqli-canary')`)
  - **XSS**: Block cross-site scripting (`evaluatePreconfiguredExpr('xss-canary')`)
  - **LFI**: Block local file inclusion (`evaluatePreconfiguredExpr('lfi-canary')`)
  - **RCE**: Block remote code execution (`evaluatePreconfiguredExpr('rce-canary')`)
  - **RFI**: Block remote file inclusion (`evaluatePreconfiguredExpr('rfi-canary')`)
  - **Scanner detection**: Block known vulnerability scanners
- Sensitivity levels (1-4): higher = more aggressive (may block legitimate traffic)
- Can be tuned with exclude rules for false positives

## Rate Limiting
- Limit requests per client (by IP, user session, or cookie)
- Configurable: rate (per minute), action (deny/throttle), enforcement duration
- Use for: API rate limiting, login brute force protection, scraping prevention
- Works with both allow and deny actions

## IP Allowlist / Denylist
- Allow traffic only from specific IP ranges (whitelist)
- Block traffic from known bad IPs (blacklist)
- Supports: IPv4, IPv6, CIDR notation
- Combine with geo-based rules for access control

## Geo-Based Rules
- Allow or deny traffic by geographic origin
- Use `origin.region_code` match expression
- Examples:
  - Block traffic from outside your target market
  - Allow only specific countries for compliance
  - Redirect certain countries to regional endpoints

## Pre-Configured WAF Rules
| Rule Name | Protection |
|-----------|------------|
| `sqli-canary` | SQL injection |
| `xss-canary` | Cross-site scripting |
| `lfi-canary` | Local file inclusion |
| `rce-canary` | Remote code execution |
| `rfi-canary` | Remote file inclusion |
| `protocol-attack-canary` | HTTP protocol compliance |
| `method-enforcement-canary` | HTTP method restrictions |
| `java-canary` | Java-specific exploits |
| `php-canary` | PHP-specific exploits |
| `cve-canary` | Specific CVE-based rules |
| `scannerdetection-canary` | Known vulnerability scanners |
| `sessionfixation-canary` | Session fixation |

## Cloud Armor Managed Protection

| Tier | Features | Best For |
|------|----------|----------|
| **Standard** (free with LB) | Security policies, OWASP rules, IP allow/deny, geo-based rules | Basic WAF protection |
| **Managed Protection Plus** ($3,000/month) | Adaptive protection (ML-based), advanced DDoS analytics, 24/7 SOC | Enterprise, high-value apps |

**Managed Protection Plus** includes:
- Adaptive Protection: ML model learns normal traffic patterns, detects anomalies, generates rules
- Real-time DDoS alerting and mitigation recommendations
- 24/7 access to Google Cloud SOC (Security Operations Center)
- Enhanced DDoS protection for L3/L4 (not just L7)

## Hands-on Example

```bash
# Create security policy
gcloud compute security-policies create my-policy \
  --description="Protect application from web attacks"

# Add OWASP SQLi rule (deny)
gcloud compute security-policies rules create 1000 \
  --security-policy=my-policy \
  --expression="evaluatePreconfiguredExpr('sqli-canary-stable')" \
  --action=deny-403 \
  --description="Block SQL injection"

# Add XSS rule
gcloud compute security-policies rules create 2000 \
  --security-policy=my-policy \
  --expression="evaluatePreconfiguredExpr('xss-canary-stable')" \
  --action=deny-403

# Add rate limiting rule (max 100 req/user/minute)
gcloud compute security-policies rules create 3000 \
  --security-policy=my-policy \
  --action=throttle \
  --rate-limit-threshold-count=100 \
  --rate-limit-threshold-interval-sec=60 \
  --conform-action=allow \
  --exceed-action=deny-429 \
  --description="Rate limit per client"

# Block specific country
gcloud compute security-policies rules create 4000 \
  --security-policy=my-policy \
  --expression="origin.region_code == 'XX'" \
  --action=deny-403 \
  --description="Block country XX"

# Allow only specific IPs
gcloud compute security-policies rules create 5000 \
  --security-policy=my-policy \
  --src-ip-ranges="10.0.0.0/8,192.168.0.0/16" \
  --action=allow \
  --description="Allow internal IPs"

# Default deny rule (priority 2147483647)
gcloud compute security-policies rules create 2147483647 \
  --security-policy=my-policy \
  --action=deny-403 \
  --description="Default deny"

# Attach policy to backend service
gcloud compute backend-services update my-backend-service \
  --security-policy=my-policy
```

## Pricing Model
- **Standard tier**: No additional cost (included with HTTP(S) Load Balancer)
- **Managed Protection Plus**: $3,000/month per month per organization (covers all projects)
- **Rate limiting**: Included in standard tier
- **Pre-configured WAF rules**: No additional cost
- **Egress**: Standard network egress (no additional for Cloud Armor processing)

## Best Practices
- Start with OWASP Top 10 rules (SQLi, XSS, RCE) in monitoring mode before enforcing
- Use rate limiting for all API endpoints
- Combine geo-based rules with IP allowlist for internal apps
- Enable Adaptive Protection (Managed Protection Plus) for enterprise apps
- Review Cloud Armor logs for false positives and tune exclusions
- Use multiple rules with increasing priority for layered protection
- Test rule changes in preview mode before enforcing
- Monitor blocked requests with Cloud Monitoring dashboards

## Interview Questions
1. How does Cloud Armor integrate with HTTP(S) Load Balancing to protect applications?
2. Explain the OWASP ModSecurity Core Rule Set categories and how to configure them in Cloud Armor
3. How does rate limiting work and how would you configure it for an API?
4. Compare Cloud Armor Standard vs Managed Protection Plus
5. Design a WAF strategy for a global e-commerce platform using Cloud Armor

## Real Company Usage
- **Niantic**: Protects Pokémon GO APIs with Cloud Armor WAF and rate limiting
- **Spotify**: Uses Cloud Armor for API protection and DDoS mitigation
- **Etsy**: Cloud Armor for OWASP protection on e-commerce platform
- **Ubisoft**: Game backend APIs protected with Cloud Armor
