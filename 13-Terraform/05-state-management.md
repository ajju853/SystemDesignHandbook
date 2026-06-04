# 05 — State Management

## What is it?

Terraform state is a JSON file that maps your configuration to real-world infrastructure. It is the **source of truth** that Terraform uses to determine what exists, what needs creating, updating, or destroying. State management covers where this file lives, how to protect it, and how to migrate it.

## Why it matters

- **Collaboration**: Team members need to share state or they'll overwrite each other
- **Locking**: Prevents concurrent operations that corrupt state
- **Sensitive data**: State may contain passwords, IPs, and other secrets
- **Disaster recovery**: Lost state = orphaned resources
- **CI/CD**: Automated pipelines need reliable state access

## Local State

```bash
$ terraform apply
# Creates terraform.tfstate in the current directory
```

**Pros**: Simple, no setup  
**Cons**: No sharing, no locking, easy to lose, insecure

```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

## Remote State

### S3 Backend (AWS)

```hcl
terraform {
  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "infra/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### GCS Backend (GCP)

```hcl
terraform {
  backend "gcs" {
    bucket = "my-company-terraform-state"
    prefix = "infra/prod"
  }
}
```

### AzureRM Backend

```hcl
terraform {
  backend "azurerm" {
    storage_account_name = "mycompanytfstate"
    container_name       = "infra"
    key                  = "prod.terraform.tfstate"
  }
}
```

### Terraform Cloud Backend

```hcl
terraform {
  cloud {
    organization = "my-company"
    workspaces {
      name = "infra-prod"
    }
  }
}
```

## DynamoDB Locking (with S3)

```hcl
terraform {
  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "infra/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

The DynamoDB table must exist with a partition key `LockID` (type String):

```hcl
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

## State Commands

### List resources in state

```bash
terraform state list
# aws_instance.web
# aws_s3_bucket.data
# module.vpc.aws_vpc.main
```

### Show a specific resource in state

```bash
terraform state show aws_instance.web
# # aws_instance.web:
# resource "aws_instance" "web" {
#     id             = "i-0a1b2c3d4e5f"
#     ami            = "ami-0c55b159cbfafe1f0"
#     instance_type  = "t2.micro"
#     ...
# }
```

### Move a resource in state

```bash
# Rename or restructure
terraform state mv aws_instance.web aws_instance.web_server
terraform state mv module.vpc.aws_vpc.main module.networking.aws_vpc.main
```

### Remove a resource from state

```bash
# Remove from state (does NOT destroy the resource)
terraform state rm aws_instance.web
```

### Import existing resources

```bash
# Import an existing resource into state
terraform import aws_s3_bucket.data my-existing-bucket
```

## `terraform_remote_state` Data Source

Read outputs from another configuration's state file:

```hcl
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "my-company-terraform-state"
    key    = "infra/shared/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = data.terraform_remote_state.shared.outputs.public_subnet_ids[0]
}
```

> ⚠ **Warning**: `terraform_remote_state` creates a tight coupling between configurations. Prefer module composition where possible.

## Migrating State

### Local → S3

```bash
# 1. Add the backend block
# 2. Run init with -migrate-state
terraform init -migrate-state
# Terraform asks: copy existing state to the new backend?
# Answer: yes
```

### S3 → Terraform Cloud

```bash
terraform init -migrate-state
```

### State file format migration

Terraform automatically migrates state files between versions on first run.

## State File Security

State files may contain:

- Resource IDs and ARNs
- Public/private IP addresses
- Database usernames and passwords (if stored in config)
- IAM keys and secret keys (if declared in config)

### Protection strategies

| Measure | Implementation |
|---------|---------------|
| **Encryption at rest** | S3 server-side encryption (`encrypt = true`) |
| **Encryption in transit** | HTTPS backends (all Terraform backends) |
| **Access control** | IAM policies restricting read/write to state bucket |
| **Audit logging** | S3 access logs, CloudTrail |
| **Sensitive marking** | `sensitive = true` on outputs |
| **Vault integration** | Store secrets externally, reference via `vault` provider |
| **State isolation** | Separate state files per environment |

### IAM policy for state access

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::my-company-terraform-state",
        "arn:aws:s3:::my-company-terraform-state/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:*:table/terraform-locks"
    }
  ]
}
```

## Best Practices

1. **Always use remote state with locking** for team environments
2. **Never manually edit** state files — use `terraform state` commands
3. **Encrypt state** at rest and in transit
4. **Restrict access** to state files — they contain sensitive data
5. **Separate state per environment** — different bucket/prefix per env
6. **Backup state** regularly (S3 versioning on the state bucket)
7. **Use `terraform state`** commands instead of editing JSON
8. **Audit state access** with CloudTrail or equivalent

## Interview Questions

| Question | Key points |
|----------|------------|
| *Why use remote state?* | Collaboration, locking, durability, CI/CD |
| *How does Terraform prevent concurrent state writes?* | DynamoDB locking (S3 backend) |
| *What's in a state file?* | Resource IDs, attributes, metadata, dependencies |
| *How do you recover from a corrupted state file?* | Restore from backup (S3 versioning) |
| *What is `terraform state mv` used for?* | Renaming or restructuring resources without destroying |
| *How do you import existing infrastructure into Terraform?* | `terraform import` |
| *What's the difference between `terraform refresh` and `terraform plan`?* | `refresh` updates state from real world; `plan` shows diff to apply |

---

**Next**: [06 — Provisioning AWS with Terraform](06-provisioning-aws.md)
