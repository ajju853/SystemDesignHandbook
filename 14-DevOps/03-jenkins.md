# 03 - Jenkins

## What is it?

Jenkins is an open-source automation server for building, testing, and deploying software. It supports declarative and scripted pipelines via Jenkinsfile, extensive plugin ecosystem, and integration with virtually every tool in the DevOps ecosystem.

## Why it matters

- Mature, battle-tested CI/CD orchestrator
- Massive plugin library (1,800+ plugins)
- Pipeline as Code via Jenkinsfile in SCM
- Distributed builds with master/agent architecture
- Rich API and webhooks for extensibility
- Blue Ocean modern UI

## Implementation

### Declarative Pipeline

```groovy
pipeline {
    agent any

    tools {
        nodejs 'Node-20'
    }

    environment {
        REGISTRY = 'ghcr.io/myorg'
        IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }
        stage('Lint & Test') {
            parallel {
                stage('Lint') {
                    steps { sh 'npm run lint' }
                }
                stage('Unit Tests') {
                    steps { sh 'npm run test:ci' }
                    post {
                        always {
                            junit 'junit.xml'
                        }
                    }
                }
            }
        }
        stage('Build & Scan') {
            steps {
                script {
                    docker.build("${REGISTRY}/my-app:${IMAGE_TAG}")
                }
                sh 'trivy image --severity HIGH,CRITICAL ${REGISTRY}/my-app:${IMAGE_TAG}'
            }
        }
        stage('Deploy to Staging') {
            steps {
                sh "kubectl set image deployment/my-app my-app=${REGISTRY}/my-app:${IMAGE_TAG} -n staging"
            }
        }
        stage('Integration Tests') {
            steps {
                sh 'npm run test:integration'
            }
        }
        stage('Approve Production') {
            input {
                message "Deploy to production?"
                ok "Yes, deploy"
                submitter "release-managers"
            }
        }
        stage('Deploy to Production') {
            steps {
                sh "kubectl set image deployment/my-app my-app=${REGISTRY}/my-app:${IMAGE_TAG} -n production"
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            emailext(
                subject: "Pipeline failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                to: 'team@example.com',
                body: "See ${env.BUILD_URL}"
            )
        }
    }
}
```

### Scripted Pipeline

```groovy
node('docker-agent') {
    try {
        stage('Checkout') {
            checkout scm
        }
        stage('Build') {
            docker.image('node:20').inside {
                sh 'npm ci && npm run build'
            }
        }
        stage('Test') {
            sh 'npm test'
        }
    } catch (e) {
        currentBuild.result = 'FAILURE'
        throw e
    } finally {
        cleanWs()
    }
}
```

### Shared Library

`vars/deployToK8s.groovy`:
```groovy
def call(String namespace, String deployment, String image) {
    sh "kubectl set image deployment/${deployment} ${deployment}=${image} -n ${namespace}"
    sh "kubectl rollout status deployment/${deployment} -n ${namespace}"
}
```

Usage in Jenkinsfile:
```groovy
@Library('my-shared-lib@main') _

pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                deployToK8s('staging', 'my-app', 'my-app:v1.2')
            }
        }
    }
}
```

### Jenkinsfile with Docker Agent

```groovy
pipeline {
    agent {
        docker {
            image 'node:20'
            args '-v /tmp/.npm-cache:/root/.npm'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'npm ci && npm run build'
            }
        }
    }
}
```

### Kubernetes Plugin — Dynamic Agents

```groovy
pipeline {
    agent {
        kubernetes {
            label 'build-agent'
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: node
    image: node:20
    command: ['cat']
    tty: true
  - name: docker
    image: docker:24
    command: ['cat']
    tty: true
    volumeMounts:
    - name: docker-socket
      mountPath: /var/run/docker.sock
  volumes:
  - name: docker-socket
    hostPath:
      path: /var/run/docker.sock
"""
        }
    }
    stages {
        stage('Build with Docker') {
            steps {
                container('docker') {
                    sh 'docker build -t my-app .'
                }
            }
        }
        stage('Test') {
            steps {
                container('node') {
                    sh 'npm test'
                }
            }
        }
    }
}
```

## Best Practices

- Keep Jenkinsfile in source control (Pipeline as Code)
- Use declarative pipeline for readability, scripted for complex logic
- Store credentials in Jenkins credentials store (never plaintext in Jenkinsfile)
- Use shared libraries for reusable pipeline code across repos
- Pin agent images and tool versions
- Use `parallel` execution for fast feedback
- Add `input` gate for production deployments
- Clean workspace in `post { always }` to save disk
- Use Blue Ocean for pipeline visualization

## Interview Questions

| Question | Answer |
|----------|--------|
| Declarative vs Scripted pipeline — differences? | Declarative: structured, `pipeline {}`, validation; Scripted: Groovy DSL, `node {}`, full flexibility |
| What is a Jenkins shared library? | Versioned repo of reusable pipeline code (`vars/*.groovy`, `src/`) loaded via `@Library` |
| How do you secure Jenkins? | Role-based auth (RBAC), credential store, agent isolation, audit logs, JCasC |
| What is Blue Ocean? | Modern Jenkins UI with pipeline visualization, branch awareness, personalized views |
| How do you integrate Jenkins with Kubernetes? | Kubernetes plugin spins ephemeral pod agents per build, dynamic scaling |
| Explain Jenkinsfile in SCM approach | Pipeline definition checked into repo; Jenkins scans branches, auto-creates pipelines (multibranch) |

## Cross-References

- [14-DevOps/02-github-actions.md](02-github-actions.md) — CI/CD alternatives to Jenkins
- [14-DevOps/07-ci-cd-pipeline-design.md](07-ci-cd-pipeline-design.md) — Pipeline stage patterns
- [09-Kubernetes](../09-Kubernetes/README.md) — K8s plugin agents
- [08-Docker](../08-Docker/README.md) — Docker pipeline integration
- [14-DevOps/04-argocd.md](04-argocd.md) — GitOps deployment as alternative
