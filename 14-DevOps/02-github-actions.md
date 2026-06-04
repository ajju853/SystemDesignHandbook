# 02 - GitHub Actions

## What is it?

GitHub Actions is a CI/CD platform that automates software workflows directly from GitHub repositories. It uses YAML-based configuration files to define jobs, steps, and runners for building, testing, and deploying code.

## Why it matters

- Tight integration with GitHub — PR checks, issues, deployments
- Hosted and self-hosted runners
- Marketplace with thousands of pre-built actions
- Matrix builds across OS, language versions
- Environments with approval gates and secrets scoping

## Implementation

### Workflow Syntax

```yaml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  workflow_dispatch:

env:
  NODE_VERSION: '20'

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
      - run: npm ci
      - run: npm run lint

  test:
    needs: lint
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node: ['18', '20', '22']
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
      - run: npm ci
      - run: npm test
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results-${{ matrix.node }}
          path: junit.xml
```

### Matrix Builds

```yaml
jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        python-version: ['3.10', '3.11', '3.12']
        exclude:
          - os: macos-latest
            python-version: '3.10'
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      - run: pip install -r requirements.txt
      - run: pytest --junitxml=report.xml
      - uses: actions/upload-artifact@v4
        with:
          name: coverage-${{ matrix.os }}-${{ matrix.python-version }}
          path: coverage.xml
```

### Environments & Secrets

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://app.example.com
    steps:
      - uses: actions/checkout@v4
      - run: echo "Deploying to ${{ vars.ENVIRONMENT_NAME }}"
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - run: |
          aws s3 sync ./dist s3://${{ secrets.S3_BUCKET }}
          aws cloudfront create-invalidation --distribution-id ${{ secrets.CF_DISTRIBUTION_ID }} --paths '/*'
```

### Deployment to Cloud Providers

**AWS ECS:**
```yaml
      - uses: aws-actions/amazon-ecs-deploy-task-definition@v2
        with:
          task-definition: task-definition.json
          service: my-service
          cluster: my-cluster
          wait-for-service-stability: true
```

**GCP Cloud Run:**
```yaml
      - uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      - uses: google-github-actions/deploy-cloudrun@v2
        with:
          service: my-service
          image: gcr.io/${{ vars.GCP_PROJECT }}/my-app:${{ github.sha }}
          region: us-central1
```

**Azure Web App:**
```yaml
      - uses: azure/webapps-deploy@v3
        with:
          app-name: my-app
          slot-name: staging
          publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
          package: .
```

### Composite Actions

`.github/actions/deploy/action.yml`:
```yaml
name: Deploy to Environment
description: Deploy application to specified environment
inputs:
  environment:
    required: true
    description: Target environment
runs:
  using: composite
  steps:
    - run: |
        echo "Deploying to ${{ inputs.environment }}"
        ./scripts/deploy.sh ${{ inputs.environment }}
      shell: bash
```

## Best Practices

- Pin action versions to full release tags (`v4`, not `@main`)
- Use `actions/cache` to speed up dependency installation
- Scope secrets to specific environments, never log them
- Use `workflow_dispatch` with input parameters for manual triggers
- Keep jobs focused — one concern per job, use `needs` for ordering
- Use `if: always()` for upload-artifact on failure
- Prefer `actions/upload-artifact` to share between jobs over `actions/cache`
- Set `timeout-minutes` on jobs to prevent runaway workflows

## Interview Questions

| Question | Answer |
|----------|--------|
| What is the difference between `on: push` and `on: pull_request`? | `push` on branch, `pull_request` triggers on PR events (synchronize, opened, reopened) |
| How do you secure secrets in GitHub Actions? | Store in repo/organization secrets, use `secrets.X`, never `echo` them, restrict environment access |
| When would you use a self-hosted runner? | Need specific hardware/GPU, on-premises deployment, air-gapped environments |
| Explain matrix strategy and how to exclude combos | `strategy.matrix` generates N jobs from lists; `exclude` removes specific combos, `include` adds extras |
| How do environments enforce approvals? | `environment` field in job; protected environments require designated approvers before running |
| What is a composite action vs Docker action? | Composite: shell steps in YAML; Docker: runs in a container image for language flexibility |

## Cross-References

- [14-DevOps/01-git-workflows.md](01-git-workflows.md) — Branch triggers & conventional commits
- [14-DevOps/07-ci-cd-pipeline-design.md](07-ci-cd-pipeline-design.md) — Pipeline stage design
- [10-AWS](../10-AWS/README.md) — AWS deployment targets
- [14-DevOps/09-devops-security.md](09-devops-security.md) — Secret scanning & supply-chain security
