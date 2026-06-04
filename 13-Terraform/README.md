# 13 - Terraform & Infrastructure as Code

## Module Overview

| # | File | Topics Covered |
|---|------|----------------|
| 01 | `01-iac-basics.md` | What is IaC, imperative vs declarative, Terraform vs CloudFormation vs Pulumi vs Ansible, state management |
| 02 | `02-terraform-core-concepts.md` | Providers, resources, data sources, variables, outputs, state files, workspaces, HCL syntax |
| 03 | `03-terraform-workflow.md` | init / plan / apply / destroy, plan output analysis, apply strategies, lock file, provider versioning |
| 04 | `04-modules.md` | Module structure, inputs/outputs, registry, version constraints, composition, reuse |
| 05 | `05-state-management.md` | Local vs remote state, S3 + DynamoDB, state commands, `terraform_remote_state`, migration, security |
| 06 | `06-provisioning-aws.md` | Full AWS infra: VPC, subnets, EC2, RDS, ALB, ASG, IAM — with complete HCL examples |
| 07 | `07-advanced-patterns.md` | `count` vs `for_each`, `dynamic` blocks, `locals`, `depends_on`, provisioners, `moved`, refactoring |
| 08 | `08-terraform-cloud.md` | Terraform Cloud/Enterprise: workspaces, remote runs, Sentinel, cost estimation, VCS, teams |
| 09 | `09-best-practices.md` | Naming, file structure, env separation, secrets, CI/CD (GitLab/GitHub Actions), Terragrunt |

## Cross-References

- **[10-AWS](../10-AWS)** — AWS services provisioned by Terraform
- **[11-Azure](../11-Azure)** — Azure Resource Manager and Terraform
- **[12-GCP](../12-GCP)** — GCP Deployment Manager and Terraform
- **[14-DevOps](../14-DevOps)** — CI/CD pipelines that run Terraform

## Prerequisites

- Terraform CLI >= 1.5
- Cloud provider account (AWS free tier recommended)
- Basic familiarity with HCL syntax
