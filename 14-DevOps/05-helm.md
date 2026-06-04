# 05 - Helm

## What is it?

Helm is the package manager for Kubernetes. It uses **charts** (bundles of pre-configured Kubernetes resources) to define, install, and upgrade applications. Helm templates parameterize YAML manifests using Go templating.

## Why it matters

- Reusable, versioned application packages
- Parameterized deployments via `values.yaml`
- Release management — install, upgrade, rollback, uninstall
- Dependency management between charts
- Supports CI/CD integration for templated deployments
- Hook system for lifecycle actions (pre/post install/upgrade)

## Implementation

### Chart Structure

```
my-chart/
├── Chart.yaml          # Metadata: name, version, apiVersion, dependencies
├── values.yaml         # Default configuration values
├── values.schema.json  # JSON Schema validation for values
├── charts/             # Subchart dependencies
├── templates/
│   ├── _helpers.tpl    # Named template definitions
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   └── tests/
│       └── test-connection.yaml
└── README.md
```

### Chart.yaml

```yaml
apiVersion: v2
name: my-app
description: A production-grade web application
type: application
version: 0.1.0
appVersion: "1.16.0"
icon: https://example.com/icon.png
keywords:
  - web
  - api
dependencies:
  - name: postgresql
    version: "~15.0.0"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
  - name: redis
    version: "~19.0.0"
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
```

### Templates — Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "my-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "my-app.selectorLabels" . | nindent 8 }}
    spec:
      serviceAccountName: {{ include "my-app.serviceAccountName" . }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.port }}
              protocol: TCP
          env:
            {{- range $key, $val := .Values.env }}
            - name: {{ $key }}
              value: {{ $val | quote }}
            {{- end }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
```

### values.yaml

```yaml
replicaCount: 2

image:
  repository: ghcr.io/myorg/my-app
  tag: ""
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8080

env:
  LOG_LEVEL: info
  NODE_ENV: production

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix

postgresql:
  enabled: true
  auth:
    database: myapp
  primary:
    persistence:
      size: 8Gi
```

### values.schema.json

```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1,
      "maximum": 100
    },
    "image": {
      "type": "object",
      "properties": {
        "repository": { "type": "string" },
        "tag": { "type": "string" }
      },
      "required": ["repository"]
    }
  },
  "required": ["replicaCount", "image"]
}
```

### Helm Hooks

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "my-app.fullname" . }}-db-migrate
  annotations:
    helm.sh/hook: post-install,post-upgrade
    helm.sh/hook-weight: "-5"
    helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migration
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          command: ["npm", "run", "migrate"]
```

### Chart Testing (helm-unittest)

`tests/deployment_test.yaml`:
```yaml
suite: test deployment
templates:
  - deployment.yaml
values:
  - ../values.yaml
tests:
  - it: should set correct replica count
    set:
      replicaCount: 3
    asserts:
      - equal:
          path: spec.replicas
          value: 3
  - it: should set container image correctly
    set:
      image.repository: nginx
      image.tag: "1.25"
    asserts:
      - equal:
          path: spec.template.spec.containers[0].image
          value: nginx:1.25
```

### Helmfile

```yaml
repositories:
  - name: bitnami
    url: https://charts.bitnami.com/bitnami

environments:
  staging:
    values:
      - env: staging
  production:
    values:
      - env: production

releases:
  - name: my-app
    namespace: {{ .Values.env }}
    chart: ./charts/my-app
    values:
      - values/{{ .Values.env }}/values.yaml
    secrets:
      - secrets/{{ .Values.env }}/secrets.yaml
  - name: redis
    namespace: {{ .Values.env }}
    chart: bitnami/redis
    version: ~19.0.0
    values:
      - values/{{ .Values.env }}/redis-values.yaml
```

## Best Practices

- Follow the [Helm best practices guide](https://helm.sh/docs/chart_best_practices/)
- Always define `_helpers.tpl` for reusable template names
- Use `values.schema.json` to validate user-supplied values
- Pin dependency versions with `~` or `^` range notation
- Run `helm lint` and `helm template --validate` in CI
- Use `helm unittest` plugin for automated chart testing
- Set `helm.sh/hook-delete-policy` to clean up hook jobs
- Use Helmfile or Helm operator for multi-environment releases

## Interview Questions

| Question | Answer |
|----------|--------|
| Helm v2 vs v3? | v3 removed Tiller, uses Kubernetes RBAC natively, improved security and CRUD model |
| What is a subchart and when to use it? | Dependency chart packaged under `charts/`; separate concerns (e.g., PostgreSQL as dependency) |
| How do you manage multiple environments with Helm? | Separate `values-{env}.yaml` files, `--values` flag override; Helmfile for orchestration |
| Explain Helm hooks lifecycle | `pre/post-install|upgrade|delete|rollback`, weighted ordering, deletion policies |
| How does `--generate-name` differ from named releases? | Named: predictable; generated: random suffix for disposable test releases |
| What is a `chart.lock` file? | Generated by `helm dependency update`, locks to specific versions for reproducible builds |

## Cross-References

- [14-DevOps/04-argocd.md](04-argocd.md) — ArgoCD uses Helm as source
- [09-Kubernetes](../09-Kubernetes/README.md) — Resources generated by Helm
- [14-DevOps/07-ci-cd-pipeline-design.md](07-ci-cd-pipeline-design.md) — Helm in CI/CD pipeline
- [13-Terraform](../13-Terraform/README.md) — Terraform Helm provider for cluster bootstrap
