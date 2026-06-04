# HPA & Scaling

## Definition
The Horizontal Pod Autoscaler (HPA) automatically scales the number of pods based on observed CPU, memory, or custom metrics. The Vertical Pod Autoscaler (VPA) adjusts CPU/memory requests. The Cluster Autoscaler adds/removes nodes. Karpenter (AWS) provisions optimal compute on demand.

## Real-World Example
A video transcoding service scales from 5 to 200 pods during peak hours using HPA with custom Prometheus metrics (queue depth). VPA recommends optimal resource sizes for new services. Cluster Autoscaler adds Spot Instances during bursts.

## Key Concepts

### HPA Scaling Loop
```mermaid
graph TB
    subgraph Metrics["Metrics Sources"]
        CPU[CPU Utilization]
        MEM[Memory Utilization]
        CUSTOM[Custom Metrics<br/>Prometheus/RabbitMQ]
        EXT[External Metrics<br/>SQS Queue Depth]
    end

    subgraph HPA["HorizontalPodAutoscaler"]
        CONTROL[Control Loop<br/>every 15s]
        FORMULA[desired = ceil(current / target)]
    end

    subgraph Actions["Scaling Actions"]
        UP[Scale Up]
        DOWN[Scale Down]
    end

    subgraph Workload["Workload"]
        DEP[Deployment / StatefulSet]
        PODS[Pod Replicas]
    end

    subgraph Infra["Infrastructure Scaling"]
        CA[Cluster Autoscaler<br/>adds nodes]
        KARP[Karpenter<br/>provisions optimal instance]
    end

    CPU --> CONTROL
    MEM --> CONTROL
    CUSTOM --> CONTROL
    EXT --> CONTROL
    CONTROL --> FORMULA
    FORMULA --> UP
    FORMULA --> DOWN
    UP --> DEP
    DOWN --> DEP
    DEP --> PODS
    PODS -->|pending pods| CA
    PODS -->|pending pods| KARP
```

## Hands-on YAML

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 3
  maxReplicas: 50
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
    - type: Pods
      pods:
        metric:
          name: requests_per_second
        target:
          type: AverageValue
          averageValue: 1000
    - type: Object
      object:
        metric:
          name: queue_depth
        describedObject:
          apiVersion: v1
          kind: Service
          name: queue-svc
        target:
          type: Value
          value: 500
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
        - type: Pods
          value: 2
          periodSeconds: 60
      selectPolicy: Max
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
      selectPolicy: Max
```

### Custom Metrics with Prometheus Adapter
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: queue-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: worker
  minReplicas: 1
  maxReplicas: 100
  metrics:
    - type: Pods
      pods:
        metric:
          name: prometheus_http_requests_total
        target:
          type: AverageValue
          averageValue: 1000
---
# Prometheus Adapter config
apiVersion: v1
kind: ConfigMap
metadata:
  name: adapter-config
  namespace: custom-metrics
data:
  config.yaml: |
    rules:
      - seriesQuery: 'http_requests_total{namespace!=""}'
        resources:
          overrides:
            namespace: {resource: "namespace"}
            pod: {resource: "pod"}
        name:
          matches: "http_requests_total"
          as: "requests_per_second"
        metricsQuery: 'rate(http_requests_total{<<.LabelMatchers>>}[2m])'
```

### VPA (Vertical Pod Autoscaler)
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: web-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  updatePolicy:
    updateMode: Auto
  resourcePolicy:
    containerPolicies:
      - containerName: nginx
        minAllowed:
          cpu: 100m
          memory: 128Mi
        maxAllowed:
          cpu: 2
          memory: 4Gi
        controlledResources: ["cpu", "memory"]
```

### Cluster Autoscaler vs Karpenter
```yaml
# Cluster Autoscaler annotations
apiVersion: v1
kind: Node
metadata:
  annotations:
    cluster-autoscaler.kubernetes.io/scale-down-disabled: "false"
---
# Karpenter provisioner
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
spec:
  requirements:
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["on-demand", "spot"]
    - key: node.kubernetes.io/instance-type
      operator: In
      values: ["m5.large", "m5.xlarge", "c5.2xlarge"]
  limits:
    resources:
      cpu: 1000
  ttlSecondsAfterEmpty: 30
  providerRef:
    name: default
```

### API-Based Scaling
```bash
# Manual scale
kubectl scale deployment web-app --replicas=10

# Autoscale command
kubectl autoscale deployment web-app --min=3 --max=50 --cpu-percent=70

# Check HPA status
kubectl get hpa web-hpa -w

# Describe HPA details
kubectl describe hpa web-hpa
```

## Best Practices
- Always set `stabilizationWindowSeconds` for scale-down to avoid thrashing.
- Use multiple metric types for more responsive scaling.
- Configure `selectPolicy: Max` for scale-up to be aggressive.
- Set VPA in `Off` mode initially to gather recommendations before applying.
- Combine HPA with Cluster Autoscaler or Karpenter for complete elasticity.
- Monitor HPA decisions with `kubectl describe hpa` for debugging.

## Interview Questions
1. How does HPA calculate the desired number of replicas?
2. What is the difference between HPA and VPA?
3. How do you add custom metrics (e.g., RabbitMQ queue depth) to HPA?
4. What is the purpose of stabilizationWindowSeconds?
5. How does Cluster Autoscaler differ from Karpenter?
