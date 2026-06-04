# Authorization

## Definition
Authorization (authz) determines what an authenticated user is permitted to do. It answers the question: "What can you access?" Authorization always comes after authentication.

## Access Control Models

| Model | Description | Granularity | Complexity | Example |
|-------|-------------|-------------|------------|---------|
| **DAC** (Discretionary) | Owner controls access per resource | Per-resource | Low | UNIX file perms, Google Drive |
| **MAC** (Mandatory) | System-enforced labels, user can't override | Label-based | Medium | Government classified docs |
| **RBAC** (Role-based) | Roles group permissions, users get roles | Role-level | Medium | Most enterprise apps |
| **ABAC** (Attribute-based) | Policies evaluate user/resource/environment attributes | Attribute-level | High | AWS IAM, Google Cloud IAM |
| **ReBAC** (Relationship-based) | Access based on relationships between entities | Relationship-level | High | Google Drive share, social networks |

## RBAC vs ABAC Comparison

```
RBAC:
  User → Role → Permissions
  ├── "Alice is Admin" → "Admin can DELETE /users"
  └── "Bob is Viewer" → "Viewer can GET /users"

ABAC:
  User + Resource + Environment → Policy → Allow/Deny
  ├── "Alice can EDIT docs she OWNS during BUSINESS_HOURS"
  ├── "Any user can READ docs marked PUBLIC"
  └── "Contractors can't ACCESS docs marked CONFIDENTIAL"

When to use RBAC:
- Simple, well-defined roles
- Few permission changes
- Small/medium teams

When to use ABAC:
- Complex, dynamic permissions
- Multi-tenant SaaS
- Compliance-driven (HIPAA, SOC2)
- Fine-grained access control
```

## Authorization in Microservices

```mermaid
graph TB
    subgraph Gateways["Authorization Patterns"]
        GW[API Gateway] -->|Centralized Authz| Svc1[Service A]
        GW -->|Centralized Authz| Svc2[Service B]
        
        Svc3[Service C] -->|PDP| PDP[Policy Decision Point<br/>OPA / Cedar Agent]
        Svc4[Service D] -->|PDP| PDP
    end
    
    subgraph Patterns["Authorization Patterns"]
        CP[Centralized PDP] -->|OPA, Cedar| All[All services query one PDP]
        DP[Distributed PEP] -->|Each service embeds| EP[Enforcement Point]
        HC[Hybrid] -->|Gateway checks coarse,<br/>Service checks fine] GC[Granular Control]
    end
```

## Principle of Least Privilege

```
Core concept: Every user/program should operate with the minimum 
permissions necessary to do their job.

Implementation:
1. Default deny — Everything is denied unless explicitly allowed
2. Time-bound access — Temporary credentials for operations
3. Just-in-time (JIT) — Elevate privileges only when needed
4. Regular audits — Review and revoke unused permissions
5. Separation of duties — No single user has all-powerful access

Example (AWS IAM):
{
  "Effect": "Allow",
  "Action": ["s3:GetObject"],
  "Resource": "arn:aws:s3:::company-data/reports/*",
  "Condition": {
    "IpAddress": {"aws:SourceIp": "10.0.0.0/16"}
  }
}
```

## Interview Questions

1. What's the difference between authentication and authorization?
2. Compare RBAC and ABAC access control models
3. How do you implement authorization in microservices?
4. What is the principle of least privilege and how do you enforce it?
5. Design an authorization system for a multi-tenant SaaS platform
6. What is OPA (Open Policy Agent) and how does it work?
