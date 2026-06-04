# 08 — Terraform Cloud / Enterprise

## What is it?

Terraform Cloud (TFC) is HashiCorp's managed service for team-based Terraform use. It provides remote state management, VCS-driven runs, policy enforcement (Sentinel), cost estimation, and collaboration features. Terraform Enterprise (TFE) is the self-hosted version of the same platform.

## Why it matters

As Terraform usage scales across an organization, problems emerge:
- **Who ran what?** — No audit trail for local runs
- **State conflicts** — Manual locking is error-prone
- **No review** — Plans applied without peer review
- **Policy compliance** — No guardrails against insecure configurations
- **Cost visibility** — No connection between infrastructure changes and cloud costs

Terraform Cloud addresses all of these with a unified platform.

## Core Features

| Feature | Description |
|---------|-------------|
| **Remote State** | Encrypted state stored in TFC, automatically managed |
| **Remote Runs** | `apply` executes on TFC runners (or your own) |
| **VCS Integration** | Auto-trigger plans on pull requests |
| **Sentinel** | Policy-as-Code framework (e.g., "deny public S3 buckets") |
| **Cost Estimation** | Estimated monthly cost per plan |
| **Team Management** | RBAC: read, plan, write, admin roles |
| **Workspaces** | Logical environments with their own state and variables |
| **API** | Full REST API for CI/CD integration |
| **Run Tasks** | External integration (e.g., Checkov, Infracost) |

## Workspaces

A workspace contains:
- Terraform configuration (pointed at a VCS repo or uploaded via API)
- State file
- Variables (Terraform + environment)
- Run history
- Settings (execution mode, apply strategy, etc.)

```hcl
# terraform.tf — point config at Terraform Cloud
terraform {
  cloud {
    organization = "mycompany"
    workspaces {
      name = "infra-prod"  # unique workspace name
    }
  }
}
```

### Workspace strategies

| Strategy | Workspace Pattern | Use Case |
|----------|------------------|----------|
| **One per env** | `infra-dev`, `infra-staging`, `infra-prod` | Standard env isolation |
| **One per project** | `networking`, `compute`, `database` | Team ownership isolation |
| **One per team** | `platform`, `backend`, `data` | Large organizations |

```hcl
# Tag-based workspace selection (TFC CLI-driven)
terraform {
  cloud {
    organization = "mycompany"
    workspaces {
      tags = ["networking", "prod"]
    }
  }
}
```

## Remote Runs

```bash
# Runs plan/apply in Terraform Cloud instead of locally
terraform plan
# Output: "Running plan in Terraform Cloud..."

terraform apply
# Runs remotely, stream output locally
```

**Execution modes**:

| Mode | Description |
|------|-------------|
| **Remote** | Plan/apply run on TFC workers (default) |
| **Local** | Plan/apply run locally, state managed in TFC |
| **Agent** | Plan/apply run on self-hosted agents (TFE) |

## VCS Integration

Connect a workspace to a Git repository:

```
Workspace → VCS → GitHub / GitLab / Bitbucket / Azure DevOps
```

Workflow:
1. Developer creates a PR with Terraform changes
2. TFC automatically runs `terraform plan`
3. Plan result posted as PR comment
4. Team reviews and merges
5. On merge to default branch, TFC runs `terraform apply`

```terraform
# .terraform-version
1.5.7
```

## Sentinel Policies

Sentinel is HashiCorp's Policy-as-Code framework. Policies are written in a custom language and evaluated before `apply`.

### Policy example: Mandatory tags

```sentinel
# mandatory-tags.sentinel
import "tfplan"

# List of required tags
mandatory_tags = ["Environment", "Owner", "CostCenter"]

# Get all resources
all_resources = filter tfplan.resource_changes as _, rc {
    rc.change.actions contains "create"
}

# Check tags
main = rule {
    all(resources, func(resource) {
        tags = resource.change.after.tags
        all(mandatory_tags, func(tag) {
            tags contains tag
        })
    })
}
```

### Policy example: Deny public S3 buckets

```sentinel
# no-public-s3.sentinel
import "tfplan"

s3_buckets = filter tfplan.resource_changes as _, rc {
    rc.type is "aws_s3_bucket" and
    (rc.change.actions contains "create" or
     rc.change.actions contains "update")
}

main = rule {
    all(s3_buckets, func(bucket) {
        acl = bucket.change.after.acl
        not acl matches "public*"
    })
}
```

### Policy sets

Policies are grouped into **policy sets** and attached to workspaces or organizations. Each policy has an enforcement level:

| Level | Behavior |
|-------|----------|
| `hard-mandatory` | Blocks apply |
| `soft-mandatory` | Blocks apply unless overridden by an admin |
| `advisory` | Passes but logs a warning |

## Cost Estimation

Terraform Cloud can estimate the monthly cost of a plan before you apply it.

```
------------------------------------------------------------------------
Cost estimation:

Resource                  Monthly Cost
aws_instance.web          ~$25.55
aws_db_instance.main      ~$45.00
aws_lb.web                ~$22.40
aws_nat_gateway.main      ~$32.00
aws_eip.nat               ~$3.60
            Total        ~$128.55
------------------------------------------------------------------------
```

Cost estimation requires:
- Workspace connected to AWS (or other supported provider)
- Cost estimation enabled in workspace settings

## Team Management

### Roles

| Role | Permissions |
|------|-------------|
| **Read** | View runs, state, and variables |
| **Plan** | Read + run plans |
| **Write** | Plan + apply + manage variables |
| **Admin** | Full workspace control |

### Organization roles

| Role | Permissions |
|------|-------------|
| **Owner** | Full organization control, billing, member management |
| **Admin** | Manage workspaces, teams, policies |
| **Member** | Access workspaces they've been granted |

## API Integration

```bash
# Trigger a run via API
curl -H "Authorization: Bearer $TFC_TOKEN" \
     -H "Content-Type: application/vnd.api+json" \
     -X POST \
     -d '{
       "data": {
         "attributes": {
           "message": "API-triggered run"
         },
         "type": "runs",
         "relationships": {
           "workspace": {
             "data": {
               "type": "workspaces",
               "id": "ws-12345"
             }
           }
         }
       }
     }' \
     https://app.terraform.io/api/v2/runs
```

## CLI Commands for TFC

```bash
# Login to Terraform Cloud
terraform login

# Init workspace
terraform init

# Set variables
terraform workspace select prod
terraform vars set -var="environment=prod"

# Create workspace from CLI
# Using terraform.tf with cloud block, then:
terraform init

# List workspaces
terraform workspace list
```

## Self-Hosted Agents (TFE)

Terraform Enterprise can run on your own infrastructure with **agents** that execute plans:

```
TFE Server → Agent Pool → Agent → Plan/Apply
```

Agents are useful for:
- Running Terraform in isolated networks (no internet access)
- Using local provisioners or tools
- Compliance requirements (data residency)

## Best Practices

1. **Use VCS-driven runs** — never run from local for production changes
2. **Structure workspaces** by environment or team, not both
3. **Use Sentinel policies** for security baseline (public S3, encryption, mandatory tags)
4. **Enable cost estimation** to catch surprise bills before they happen
5. **Set `auto-apply` to false** for production workspaces
6. **Use teams and RBAC** — don't give Write access to everyone
7. **Pin provider versions** in `required_providers` even in TFC
8. **Use run tasks** for third-party validation (Checkov, tfsec, Infracost)

## Interview Questions

| Question | Key points |
|----------|------------|
| *What is Terraform Cloud vs Terraform Enterprise?* | TFC = SaaS; TFE = self-hosted; same features |
| *How does Terraform Cloud handle state?* | Remote state encrypted at rest, no need for S3 backend |
| *What is Sentinel?* | Policy-as-Code language that gates applies (hard-mandatory, soft-mandatory, advisory) |
| *What are run tasks?* | External API integrations that validate plans (security scanning, cost estimation) |
| *How do teams collaborate in TFC?* | Workspaces + Teams + RBAC + VCS integration |
| *What execution modes does TFC support?* | Remote, Local, Agent |

---

**Next**: [09 — Best Practices](09-best-practices.md)
