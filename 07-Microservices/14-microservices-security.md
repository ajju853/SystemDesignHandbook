# Microservices Security

## What Is It?

Microservices security encompasses the strategies, protocols, and infrastructure used to authenticate, authorize, and protect communication between microservices, as well as between clients and the system. Unlike monolithic security (a single perimeter), microservices require a **defense-in-depth** approach: secure service-to-service communication, identity federation, API authorization, secret management, container security, and network policies.

```mermaid
graph TD
    subgraph SecurityLayers["Microservices Security Layers"]
        Layer1["1. Transport Security<br/>mTLS / TLS 1.3"]
        Layer2["2. Identity & Authentication<br/>SPIFFE / JWT / OAuth2"]
        Layer3["3. Authorization<br/>RBAC / ABAC / OPA"]
        Layer4["4. Secret Management<br/>Vault / Sealed Secrets"]
        Layer5["5. Container Security<br/>Security Context / Image Scanning"]
        Layer6["6. Network Security<br/>K8s NetworkPolicy / Cilium"]
    end

    Layer1 --> Layer2
    Layer2 --> Layer3
    Layer3 --> Layer4
    Layer4 --> Layer5
    Layer5 --> Layer6

    subgraph Threats["Threats Mitigated"]
        T1["Eavesdropping"]
        T2["Impersonation"]
        T3["Privilege Escalation"]
        T4["Credential Theft"]
        T5["Container Escape"]
        T6["Lateral Movement"]
    end

    Layer1 -.-> T1
    Layer2 -.-> T2
    Layer3 -.-> T3
    Layer4 -.-> T4
    Layer5 -.-> T5
    Layer6 -.-> T6
```

## Why It Was Created

Monolithic applications had a single network perimeter — the app server. Microservices expand the attack surface dramatically:
- Each service is a separate network endpoint
- Inter-service traffic crosses the network (susceptible to eavesdropping)
- Each service needs its own identity and authorization
- Secrets (DB passwords, API keys) must be shared across many services
- Containerized workloads introduce new vulnerabilities (image CVEs, container escape)

## When to Use It

| Security Measure | When to Implement |
|-----------------|-------------------|
| mTLS between services | Always — every microservice deployment |
| JWT/OAuth2 for client auth | When clients are external (web, mobile, third-party) |
| SPIFFE/SPIRE | Production clusters with >10 services |
| RBAC/ABAC | When services have role-based access needs |
| Vault for secrets | Any service using DB passwords, API keys, or certs |
| Container security context | Every Kubernetes deployment |
| Network policies | Production Kubernetes clusters |
| API security (OWASP) | Public-facing APIs |

## Architecture Deep-Dive

### Service-to-Service Authentication

```mermaid
sequenceDiagram
    participant SA as Service A
    participant SAProxy as "Envoy (A)"
    participant SBProxy as "Envoy (B)"
    participant SB as Service B
    participant SPIRE as "SPIRE Server"

    SA ->> SAProxy: Outbound request to B

    Note over SAProxy,SPIRE: mTLS Path
    SAProxy ->> SPIRE: Fetch SVID (spiffe://domain/sa/service-a)
    SPIRE -->> SAProxy: SVID + Key
    SAProxy ->> SBProxy: mTLS handshake (present SVID)
    SBProxy ->> SPIRE: Verify SVID
    SPIRE -->> SBProxy: Valid
    SBProxy ->> SAProxy: mTLS established

    Note over SAProxy,SBProxy: JWT Path
    SAProxy ->> SAProxy: Sign JWT with service identity
    SAProxy ->> SBProxy: Request + JWT (Authorization header)
    SBProxy ->> SBProxy: Validate JWT signature
    SBProxy ->> SB: Forward request (authenticated identity)

    SB -->> SAProxy: Response
```

### SPIFFE/SPIRE Identity Framework

**SPIFFE (Secure Production Identity Framework for Everyone)** defines an identity format and API for workloads:

```
SPIFFE ID: spiffe://trust-domain/path
Example:    spiffe://production.example.com/ns/payments/sa/payment-svc
```

**SPIRE** implements SPIFFE. It issues SVIDs (SPIFFE Verifiable Identity Documents) in X.509 or JWT format.

```mermaid
graph TB
    subgraph SPIREDeployment["SPIRE Deployment"]
        Server["SPIRE Server<br/>- CA<br/>- Registration<br/>- Attestation"]
        Agent1["SPIRE Agent<br/>(Node 1)"]
        Agent2["SPIRE Agent<br/>(Node 2)"]
    end

    subgraph Workloads1["Node 1 Workloads"]
        W1["Payment Service<br/>spiffe://domain/ns/payments/sa/payment"]
        W2["Order Service<br/>spiffe://domain/ns/orders/sa/order"]
    end

    subgraph Workloads2["Node 2 Workloads"]
        W3["User Service<br/>spiffe://domain/ns/users/sa/user"]
        W4["Inventory Service<br/>spiffe://domain/ns/inventory/sa/inventory"]
    end

    Server -->|"Attest node"| Agent1
    Server -->|"Attest node"| Agent2
    Server -->|"Registration entries"| Agent1
    Server -->|"Registration entries"| Agent2
    Agent1 -->|"Fetch SVID"| W1
    Agent1 -->|"Fetch SVID"| W2
    Agent2 -->|"Fetch SVID"| W3
    Agent2 -->|"Fetch SVID"| W4

    W1 -->|"mTLS with SVID"| W3
    W2 -->|"mTLS with SVID"| W4
```

```bash
# Register a workload with SPIRE
spire-server entry create \
  -spiffeID spiffe://prod.example.com/ns/payments/sa/payment-svc \
  -parentID spiffe://prod.example.com/ns/k8s/node/worker-1 \
  -selector k8s:sa:payment-svc \
  -selector k8s:ns:payments \
  -ttl 3600
```

### OAuth2 Client Credentials Flow

```mermaid
sequenceDiagram
    participant Client
    participant Gateway as API Gateway
    participant Auth as Auth Server (OAuth2)
    participant SvcA as Service A
    participant SvcB as Service B

    Client->>Auth: POST /token (client_id + client_secret + grant_type=client_credentials)
    Auth-->>Client: access_token (JWT)
    Client->>Gateway: GET /api/resource (Authorization: Bearer token)
    Gateway->>Auth: Introspect / validate token
    Auth-->>Gateway: Token valid (scopes, client_id)

    Gateway->>SvcA: Forward request (with JWT)
    SvcA->>SvcB: Internal call (exchange JWT via token exchange)
    SvcB->>SvcB: Validate JWT (local, no introspection needed)

    SvcB-->>SvcA: Response
    SvcA-->>Gateway: Response
    Gateway-->>Client: Response
```

```yaml
# Spring OAuth2 Client Credentials Configuration
spring:
  security:
    oauth2:
      client:
        registration:
          payment-service:
            provider: auth-server
            client-id: payment-service
            client-secret: ${PAYMENT_CLIENT_SECRET}
            authorization-grant-type: client_credentials
            scope: payment:read,payment:write
        provider:
          auth-server:
            token-uri: https://auth.example.com/oauth2/token
      resourceserver:
        jwt:
          issuer-uri: https://auth.example.com
          jwk-set-uri: https://auth.example.com/oauth2/jwks
```

### API Authorization: RBAC vs ABAC

```mermaid
graph TB
    subgraph RBAC["Role-Based Access Control (RBAC)"]
        U1["User"] --> R1["Role: admin"]
        U2["User"] --> R2["Role: viewer"]
        R1 --> P1["Permission: create:order"]
        R1 --> P2["Permission: delete:order"]
        R2 --> P3["Permission: read:order"]
    end

    subgraph ABAC["Attribute-Based Access Control (ABAC)"]
        U3["User"] -->|"Attributes: {dept: finance, level: manager}"| Policy["Policy Engine<br/>(OPA / Casbin)"]
        Request["Request: {action: approve, resource: order/123, amount: 5000}"] --> Policy
        Policy -->|"Allow if: user.dept == resource.dept && amount < 10000"| Decision["Decision: ALLOW"]
    end
```

```rego
# OPA (Open Policy Agent) - ABAC policy for microservices
package authz

import future.keywords.if

default allow := false

# RBAC rules
allow if {
    input.user.roles[_] == "admin"
}

allow if {
    input.user.roles[_] == "payment-operator"
    input.method == "POST"
    input.path == "/api/v1/payments"
}

# ABAC rules - approve payments under $10k
allow if {
    input.user.department == "finance"
    input.user.clearance_level >= 3
    input.resource.type == "payment"
    input.resource.amount < 10000
}

# ABAC - deny if amount exceeds user's limit
deny["amount_exceeds_limit"] if {
    input.resource.amount > input.user.approval_limit
}

# Scoped access - user can only access their own resources
allow if {
    input.user.id == input.resource.owner_id
    input.method == "GET"
}
```

### Secret Distribution with Vault Sidecar

```mermaid
graph TD
    subgraph VaultInfra["Vault Infrastructure"]
        Vault["HashiCorp Vault<br/>Secrets Engine"]
    end

    subgraph Pod["Kubernetes Pod"]
        App["Application Container"]
        Sidecar["Vault Agent Sidecar"]
        SharedVol["Shared Memory Volume<br/>(emptyDir)"]
    end

    App -->|"Read secrets from file"| SharedVol
    Sidecar -->|"Authenticate (K8s auth)"| Vault
    Sidecar -->|"Write secrets"| SharedVol
    Sidecar -->|"Renew leases"| Vault

    Vault -->|"Kubernetes auth"| K8sAPI["Kubernetes API<br/>ServiceAccount token"]
```

```yaml
# Vault Agent sidecar injection annotation
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "payment-svc"
    vault.hashicorp.com/agent-inject-secret-db-creds: "secret/data/payments/db"
    vault.hashicorp.com/agent-inject-template-db-creds: |
      {{- with secret "secret/data/payments/db" -}}
      export DB_USERNAME="{{ .Data.data.username }}"
      export DB_PASSWORD="{{ .Data.data.password }}"
      {{- end -}}
spec:
  template:
    spec:
      serviceAccountName: payment-svc
      containers:
      - name: payment-service
        image: payment-service:1.0.0
        env:
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: vault-db-creds
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: vault-db-creds
              key: password
```

```bash
# Configure Vault Kubernetes auth
vault auth enable kubernetes
vault write auth/kubernetes/config \
  kubernetes_host=https://kubernetes.default.svc \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Create role for payment service
vault write auth/kubernetes/role/payment-svc \
  bound_service_account_names=payment-svc \
  bound_service_account_namespaces=payments \
  policies=payment-policy \
  ttl=1h
```

### Container Security Context

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        runAsGroup: 10001
        fsGroup: 10001
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: payment-service
        image: payment-service:1.0.0
        securityContext:
          allowPrivilegeEscalation: false
          privileged: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
          seLinuxOptions:
            level: "s0:c123,c456"
        volumeMounts:
        - mountPath: /tmp
          name: tmp-volume
      volumes:
      - name: tmp-volume
        emptyDir: {}
```

### Network Policies (Kubernetes + Cilium)

```mermaid
graph TD
    subgraph Namespaces
        subgraph Payments["payments"]
            PS["Payment Service<br/>Pod"]
        end
        subgraph Orders["orders"]
            OS["Order Service<br/>Pod"]
        end
        subgraph Monitoring["monitoring"]
            PR["Prometheus<br/>Pod"]
        end
        subgraph Ingress["ingress-nginx"]
            IG["Ingress<br/>Controller"]
        end
    end

    subgraph NetworkPolicy["Network Policies"]
        NP1["Block all ingress by default"]
        NP2["Allow ingress: orders -> payments:8080"]
        NP3["Allow ingress: prometheus -> :9090"]
    end

    IG -.->|"allow"| PS
    OS -.->|"allow :8080"| PS
    PR -.->|"allow :9090"| PS
```

```yaml
# Default deny-all ingress for the payments namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: payments
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
# Allow orders service to call payment service on port 8080
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-orders-to-payments
  namespace: payments
spec:
  podSelector:
    matchLabels:
      app: payment-service
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: orders
      podSelector:
        matchLabels:
          app: order-service
    ports:
    - port: 8080
---
# Allow ingress controller to reach payment API
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-payments
  namespace: payments
spec:
  podSelector:
    matchLabels:
      app: payment-service
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ingress-nginx
    ports:
    - port: 8080
---
# Cilium Network Policy (L7-aware)
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: l7-policy
  namespace: payments
spec:
  endpointSelector:
    matchLabels:
      app: payment-service
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: order-service
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
      rules:
        http:
        - method: "POST"
          path: "/api/v1/charges"
        - method: "GET"
          path: "/api/v1/charges/{id}"
```

### OWASP Microservices Security Checklist

| Category | Control | Recommendation |
|----------|---------|----------------|
| **T1: Authentication** | JWT validation | Validate signature, expiry, issuer, audience on every request |
| **T2: Authorization** | OPA / Casbin | Externalize authorization logic; never embed in service code |
| **T3: Transport** | mTLS | Enforce mutual TLS for all inter-service communication |
| **T4: Secrets** | Vault / K8s Secrets | Never hardcode secrets; use sealed secrets or vault sidecar |
| **T5: Input** | Request validation | Validate and sanitize all inputs at the API gateway |
| **T6: Rate Limiting** | Per-client throttle | Prevent abuse and DoS with token bucket per API key |
| **T7: Audit** | Audit logging | Log all auth decisions, access attempts, and admin actions |
| **T8: Dependency** | SBOM + scanning | Generate software bill of materials; scan for CVEs in CI/CD |
| **T9: Supply Chain** | Image signing | Sign container images with cosign; verify at deployment |
| **T10: Monitoring** | Security monitoring | Detect anomalous access patterns; alert on failed auth spikes |

## Hands-On Example

### mTLS with Cert-Manager and Istio

```yaml
# Issuer for Istio CA (using cert-manager)
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: istio-ca-issuer
spec:
  ca:
    secretName: istio-ca
---
# Certificate for a service
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: payment-service-cert
  namespace: payments
spec:
  secretName: payment-service-tls
  duration: 2160h
  renewBefore: 360h
  subject:
    organizations:
    - payment-service
  commonName: payment-service.payments.svc.cluster.local
  dnsNames:
  - payment-service
  - payment-service.payments
  - payment-service.payments.svc.cluster.local
  issuerRef:
    name: istio-ca-issuer
    kind: ClusterIssuer
---
# Istio PeerAuthentication enforcing strict mTLS
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: strict-mtls
  namespace: payments
spec:
  mtls:
    mode: STRICT
```

### JWT Authentication with Spring Security

```java
// Security configuration
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/health/**", "/actuator/**").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/v1/payments").hasAuthority("SCOPE_payment:write")
                .requestMatchers(HttpMethod.GET, "/api/v1/payments/**").hasAuthority("SCOPE_payment:read")
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt
                    .jwtAuthenticationConverter(new JwtAuthenticationConverter())
                )
            )
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        return http.build()
    }

    @Bean
    public JwtDecoder jwtDecoder() {
        return NimbusJwtDecoder
            .withJwkSetUri("https://auth.example.com/oauth2/jwks")
            .jwsAlgorithm(SignatureAlgorithm.RS256)
            .build()
    }
}

// Service with method-level security
@Service
public class PaymentService {

    @PreAuthorize("hasAuthority('SCOPE_payment:admin')")
    public PaymentResponse refundPayment(String paymentId) {
        return paymentClient.refund(paymentId)
    }

    @PostAuthorize("returnObject.ownerId == authentication.name")
    public PaymentResponse getPayment(String paymentId) {
        return paymentClient.getPayment(paymentId)
    }
}
```

### SPIRE Setup for Kubernetes

```bash
# Deploy SPIRE on Kubernetes
helm repo add spiffe https://spiffe.github.io/helm-charts-hardened/
helm repo update

# Install SPIRE
helm install spire spiffe/spire --namespace spire-system --create-namespace \
  --set spiffe.spire-server.enabled=true \
  --set spiffe.spire-agent.enabled=true

# Create registration entry for a service
kubectl exec -n spire-system deploy/spire-server -- \
  /opt/spire/bin/spire-server entry create \
  -spiffeID spiffe://prod.example.com/ns/payments/sa/payment-svc \
  -parentID spiffe://prod.example.com/ns/spire-system/sa/spire-agent \
  -selector k8s:sa:payment-svc \
  -selector k8s:ns:payments

# Verify the entry
kubectl exec -n spire-system deploy/spire-server -- \
  /opt/spire/bin/spire-server entry show

# Test workload attestation
kubectl exec -n spire-system ds/spire-agent -- \
  /opt/spire/bin/spire-agent api fetch x509 \
  -socketPath /run/spire/sockets/agent.sock
```

### Vault Dynamic Secrets for Database

```bash
# Enable database secrets engine
vault secrets enable database

# Configure PostgreSQL connection
vault write database/config/payment-db \
  plugin_name=postgresql-database-plugin \
  allowed_roles="payment-role" \
  connection_url="postgresql://{{username}}:{{password}}@postgres:5432/payments" \
  username="vault-admin" \
  password="$(cat /secrets/db-pass)"

# Create dynamic role (leases DB credentials)
vault write database/roles/payment-role \
  db_name=payment-db \
  creation_statements="CREATE USER \"{{name}}\" WITH PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"

# Request credentials (dynamic, short-lived)
vault read database/creds/payment-role

# Output:
# Key                Value
# lease_id           database/creds/payment-role/A3b2C1...
# password           a8b3f2c1-d4e5-6789-abcd-ef0123456789
# username           v-token-payment-role-x7y8z9a0b1c2
```

## Pricing / Cost Considerations

| Component | Cost | Notes |
|-----------|------|-------|
| **SPIRE (self-managed)** | Free | Operational cost for SPIRE server (1-2 vCPU, 2GB RAM) |
| **HashiCorp Vault (self-managed)** | Free | Vault Enterprise from $50/seat/month |
| **Vault on HCP** | From $0.20/hr | Managed; includes replication, auto-unseal |
| **cert-manager** | Free | Open source; Let's Encrypt integration is free |
| **mTLS overhead** | ~0.5-2ms latency per hop | CPU cost for crypto operations |
| **OPA (Open Policy Agent)** | Free | Sidecar or kube-mgmt; ~50MB memory per agent |
| **Cilium** | Free | Network policy enforcement; eBPF overhead ~3% CPU |
| **External OAuth provider** | From $0 (Auth0 free tier) | Auth0: 7k free users; Okta: from $2/user/month |
| **Container image scanning** | Free (Trivy) | Trivy, Grype, Snyk (free tier limited) |

## Best Practices

1. **Defense in depth** — never rely on a single security control; combine network, transport, identity, and authorization
2. **Enforce mTLS everywhere** — use STRICT mode in service mesh; PERMISSIVE only during migration
3. **Use short-lived credentials** — dynamic secrets (Vault) limit blast radius of a leak
4. **Least privilege** — grant only the permissions a service actually needs (K8s RBAC + OPA)
5. **Validate JWT at the gateway** — reject invalid tokens before they reach services
6. **Scan images in CI/CD** — block deployments with critical CVEs; use distroless base images
7. **Audit every auth decision** — log allowed and denied requests for incident response
8. **Rotate secrets automatically** — automated rotation with Vault; never manual
9. **Segment networks** — namespace isolation + network policies; zero-trust networking
10. **Immutable infrastructure** — every deployment is an immutable artifact; patch old images, don't hotfix

## Interview Questions

1. How does SPIFFE/SPIRE provide identity to microservices? Compare with Kubernetes service accounts.
2. Explain the difference between mTLS and TLS. Why is mutual authentication important for microservices?
3. How would you implement service-to-service authorization using OPA?
4. Describe the OAuth2 Client Credentials flow. When would you use it over JWT?
5. What is a Vault sidecar and how does it handle secret rotation?
6. What Kubernetes security contexts would you apply to a payment service pod?
7. How do Cilium network policies differ from Kubernetes NetworkPolicy? When would you use Cilium?
8. Explain a zero-trust network model for microservices. How does it differ from perimeter-based security?
9. What are the OWASP Top 10 risks specific to microservices? How would you mitigate each?
10. How would you design a secrets strategy for 100+ microservices across multiple Kubernetes clusters?

## Real Company Usage

| Company | Security Practices | Details |
|---------|-------------------|---------|
| **Netflix** | mTLS, SPIRE, Vault | All inter-service traffic via mTLS; SPIRE for workload identity; Vault for secrets |
| **Uber** | OAuth2, OPA, Cilium | OAuth2 client credentials for service auth; OPA for fine-grained authz; Cilium for L7 policies |
| **Google** | SPIFFE (originated), mTLS | Borg/Google's internal system inspired SPIFFE; all services have cryptographic identity |
| **Lyft** | Envoy mTLS, SPIRE | Lyft's Envoy team pioneered sidecar mTLS; SPIRE for identity |
| **Pinterest** | Vault, OAuth2, container security | Vault for secrets; OAuth2 for API auth; seccomp and AppArmor for containers |
| **Capital One** | Vault, Cilium, OPA | Regulated finance sector; Vault for secrets management; Cilium for network policies; OPA for authz |
| **Slack** | mTLS, OPA, network policies | All inter-service traffic secured; OPA for authorization; Kubernetes NetworkPolicy for segmentation |
| **Adobe** | Vault, SPIFFE, OAuth2 | Multi-cloud microservices; SPIFFE for cross-cloud identity; Vault for secrets across environments |
