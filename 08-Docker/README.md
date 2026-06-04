# 08 — Docker

> Containerization platform for building, shipping, and running applications in isolated environments.

```mermaid
graph TB
    subgraph Core["Docker Core"]
        CLI[Docker CLI] --> Daemon[Docker Daemon dockerd]
        Daemon --> Containerd[containerd]
        Containerd --> Runc[runc]
        Daemon --> BuildKit[BuildKit]
    end

    subgraph Artifacts["Artifacts"]
        DF[Dockerfile] --> BuildKit
        BuildKit --> Image[Docker Image]
        Image --> Registry[Docker Registry<br/>Docker Hub / ECR / GCR]
        Registry --> Image
    end

    subgraph Runtime["Runtime"]
        Image --> Container[Docker Container]
        Daemon --> Network[Docker Networking<br/>bridge/overlay/host]
        Daemon --> Storage[Docker Volumes<br/>bind/volume/tmpfs]
        Daemon --> Compose[Docker Compose]
        Daemon --> Swarm[Docker Swarm]
    end

    style CLI fill:#2496ed,color:#fff
    style Daemon fill:#2496ed,color:#fff
    style Containerd fill:#2496ed,color:#fff
    style Runc fill:#2496ed,color:#fff
    style Registry fill:#f5a623,color:#fff
```

## Topics

| # | Topic | Description |
|---|-------|-------------|
| 1 | [Docker Basics](01-docker-basics.md) | Architecture, installation, containers vs VMs |
| 2 | [Dockerfile](02-dockerfile.md) | Instructions, multi-stage builds, best practices |
| 3 | [Docker Compose](03-docker-compose.md) | Multi-container orchestration with YAML |
| 4 | [Docker Networking](04-docker-networking.md) | Bridge, overlay, host, macvlan drivers |
| 5 | [Docker Storage](05-docker-storage.md) | Volumes, bind mounts, tmpfs, backup strategies |
| 6 | [Docker Security](06-docker-security.md) | Non-root, capabilities, seccomp, image scanning |
| 7 | [Docker Swarm](07-docker-swarm.md) | Native orchestration, services, stacks |
| 8 | [Docker Production](08-docker-production.md) | Best practices, monitoring, orchestration comparison |
| 9 | [Container Registries](09-docker-registries.md) | Harbor, Docker Hub, ECR, GCR, ACR, image signing, scanning |
| 10 | [Docker in CI/CD](10-docker-cicd.md) | Layer caching, multi-arch builds, BuildKit, Kaniko, Docker Bake |
| 11 | [Logging & Monitoring](11-docker-logging-monitoring.md) | Logging drivers, cAdvisor, resource constraints, healthchecks |
| 12 | [Advanced Networking](12-docker-advanced-networking.md) | Overlay encryption, IPv6, Calico, Weave, Cilium, MACVLAN |
| 13 | [Volume Management](13-docker-volume-management.md) | Backup/restore, migration, Portworx, REX-Ray, NFS, tmpfs |
| 14 | [Debugging & Troubleshooting](14-docker-debugging.md) | docker inspect, nsenter, ephemeral debug, common issues |

---

Previous: [07 — Microservices](../07-Microservices/README.md)
Next: [09 — Kubernetes](../09-Kubernetes/README.md)
