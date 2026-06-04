# Reddit Launch Posts

## r/programming — "I built a free system design resource with 450+ topics and 550+ diagrams"

**Title:** I built a completely free system design resource — 25 modules, 450+ topics, 550+ diagrams, 22 real architecture case studies

**Body:**

Hey r/programming,

I wanted to share a resource I've been building that's grown way beyond what I initially planned.

It's a completely free, open-source system design handbook on GitHub that covers everything from CAP theorem to running production incidents at staff-engineer level.

**The modules (25 total):**
01 — CS Fundamentals (CAP, scalability, latency)
02 — Networking (TCP/IP, HTTP/3, DNS, CDN)
03 — Linux (processes, memory, eBPF, systemd)
04 — Databases (SQL, NoSQL, sharding, Redis)
05 — System Design (caching, queues, load balancers)
06 — Distributed Systems (Raft, Paxos, gossip, CRDTs)
07 — Microservices (DDD, Saga, CQRS, service mesh)
08 — Docker (14 files: registries, CI/CD, debugging)
09 — Kubernetes (pods → operators, 16 files)
10-12 — AWS (42), Azure (25), GCP (26) service deep-dives
13 — Terraform (IaC, modules, state, CDKTF)
14 — DevOps (CI/CD, GitOps, ArgoCD, platform engineering)
15 — SRE (SLOs, error budgets, burn rate alerting)
16 — Security (zero trust, OWASP, TLS/mTLS, threat modeling)
17 — Observability (eBPF, Prometheus, Grafana, OpenTelemetry)
18 — Case Studies (22 real architectures: Netflix, Figma, Cloudflare, Roblox...)
19 — Projects (19 hands-on implementations)
20 — Interview Prep (26 problems from Tinder to distributed KV store)
21 — Staff Engineer (strategy, mentorship, executive comm)
22 — AI/ML System Design (LLMs, RAG, vLLM, vector DBs)
23 — API Design (REST, GraphQL, gRPC, OAuth2)
24 — Testing & Quality (contract testing, chaos, k6)
25 — Clean Architecture (SOLID, DDD, CQRS, event sourcing)

Every file has: What is it → Why → When → Mermaid diagram → Hands-on example → Interview questions → Real company usage.

**Links:** https://github.com/ajju853/SystemDesignHandbook

PRs welcome, there's a validation CI pipeline to catch broken links and format issues. Would love feedback on what's missing!

---

## r/devops — "Free DevOps/SRE/Cloud resource: 25 modules with hands-on examples"

**Title:** Comprehensive free DevOps/SRE resource covering AWS/Azure/GCP, K8s, Terraform, CI/CD, and observability

**Body:**

Sharing a resource that's been my side project for a while — it's a 25-module system design and cloud engineering handbook with hands-on examples and Mermaid diagrams for every topic.

**DevOps/SRE-specific modules:**
- 08-Docker (14 files: registries, CI/CD integration, debugging advanced networking)
- 09-Kubernetes (16 files: pods, deployments, HPA, operators, network policies)
- 10-AWS (41 files: EC2, Lambda, EKS, RDS, DynamoDB, MSK...)
- 11-Azure (25 files: VMs, AKS, Cosmos DB, Front Door...)
- 12-GCP (26 files: GKE, BigQuery, Spanner, Cloud Run...)
- 13-Terraform (12 files: modules, state, CDKTF, best practices at scale)
- 14-DevOps (14 files: Git workflows, GitHub Actions, ArgoCD, Helm, platform engineering)
- 15-SRE (14 files: SLOs, error budgets, multi-window burn-rate alerting, incident management)
- 16-Security (21 files: zero trust, OWASP, TLS/mTLS, threat modeling)
- 17-Observability (17 files: Prometheus, Grafana, OpenTelemetry, eBPF)

There's also a 7-incident postmortem collection (Facebook BGP, AWS Kinesis, Fastly CDN, etc.) with root causes and takeaways.

**GitHub:** https://github.com/ajju853/SystemDesignHandbook

What's missing from a DevOps/SRE perspective? Anything you'd want to see added?

---

## r/ExperiencedDevs — "From IC to Staff Engineer: 25-module free resource covering architecture, leadership, and strategy"

**Title:** I compiled a 25-module resource covering what I wish I knew moving from IC to Staff Engineer

**Body:**

Over the past year I've been compiling a structured learning resource that covers the full spectrum from writing your first distributed system to operating at Staff+ level.

What I found is that most resources either focus purely on interview prep (surface-level) or dive so deep into one topic they lose the big picture. This is my attempt at bridging both.

**Modules relevant to Staff+ engineers:**
- 21-Staff Engineer (19 files): tradeoffs, architecture reviews, RFC writing, technical strategy, mentorship vs sponsorship, migration strategies, executive communication, incident leadership, engineering culture (DORA/SPACE), growth paths
- 18-Case Studies (22 architectures + 7 incidents): real systems reverse-engineered
- 22-AI/ML System Design: understanding the infra behind LLMs, RAG, model serving
- 25-Clean Architecture: SOLID, DDD, CQRS, event sourcing, ADRs, twelve-factor app
- 17-Observability: SLI/SLO deep-dive, eBPF, on-call practices, maturity models

**Repo:** https://github.com/ajju853/SystemDesignHandbook

Curious what Staff+ engineers think is missing — especially around organizational design, cross-team strategy, and technical decision-making at scale. Happy to add more content.
