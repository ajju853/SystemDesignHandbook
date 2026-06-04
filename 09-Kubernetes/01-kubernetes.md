# Kubernetes (K8s)

## Definition
Kubernetes is an open-source container orchestration platform that automates deployment, scaling, and management of containerized applications.

## Architecture

```mermaid
graph TB
    subgraph CP["Control Plane"]
        AP[API Server<br/>kube-apiserver]
        SCH[Scheduler<br/>kube-scheduler]
        CM[Controller Manager]
        ETCD[etcd<br/>cluster state store]
        
        AP --- SCH
        AP --- CM
        AP --- ETCD
    end
    
    CP -->|REST API| WN1
    CP -->|REST API| WN2
    
    subgraph WN1["Worker Node 1"]
        K1[kubelet]
        CR1[Container Runtime<br/>Docker/containerd]
        KP1[kube-proxy]
        POD1[Pod<br/>app-container]
        POD2[Pod<br/>sidecar]
        
        K1 --- CR1
        K1 --- KP1
        CR1 --- POD1
        CR1 --- POD2
    end
    
    subgraph WN2["Worker Node 2"]
        K2[kubelet]
        CR2[Container Runtime]
        KP2[kube-proxy]
        POD3[Pod]
        POD4[Pod]
        
        K2 --- CR2
        K2 --- KP2
        CR2 --- POD3
        CR2 --- POD4
    end
    
    INGRESS[Ingress<br/>HTTP/S routing] -.-> POD1
    SERVICE[Service<br/>stable endpoint] -.-> POD1
    SERVICE -.-> POD3
```

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Pod** | Smallest deployable unit (1+ containers) |
| **Deployment** | Declarative pod updates (rollout/rollback) |
| **Service** | Stable network endpoint for pods |
| **ConfigMap/Secret** | Configuration and secrets |
| **Ingress** | HTTP/S traffic routing |
| **PersistentVolume** | Storage abstraction |
| **Namespace** | Virtual cluster isolation |

## Related Topics
- [Docker](../08-Docker/01-docker-basics.md) — Container runtime foundation
- [EKS/GKE/AKS](13-eks-gke-aks.md) — Managed Kubernetes comparison (within K8s module)
- [AWS Overview](../10-AWS/01-aws-overview.md) — Major cloud provider
- [Service Discovery](../06-Distributed-Systems/08-service-discovery.md) — How services find each other
- [VPC Networking](../10-AWS/08-vpc-networking.md) — Network isolation in cloud

## Interview Questions
1. How does Kubernetes handle pod scheduling?
2. What's the difference between a Deployment and a StatefulSet?
3. How does Kubernetes service discovery work?
4. How would you handle a pod that's crash-looping?
5. Design a production-grade Kubernetes cluster architecture
