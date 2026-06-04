# 02 — Terraform Core Concepts

## What is it?

Terraform is an open-source Infrastructure as Code tool created by HashiCorp. It uses the **HashiCorp Configuration Language (HCL)** to define and provision infrastructure across any cloud provider. The core abstraction is a directed acyclic graph (DAG) of resources that Terraform resolves to determine create, update, or destroy operations.

## Why it matters

Understanding the building blocks of Terraform — providers, resources, data sources, variables, outputs, and state — is essential before writing any real configuration. These concepts form the language you use every day as a Terraform practitioner.

## Core Concepts with HCL Examples

### Providers

Providers are plugins that Terraform uses to interact with cloud APIs. Each provider exposes its own set of resources and data sources.

```hcl
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  # Credentials from environment variables / IAM role
}
```

- **Source**: `namespace/type` (e.g., `hashicorp/aws`) — downloaded from the Terraform Registry
- **Version**: constraint string (`~> 5.0` means `>= 5.0, < 6.0`)
- **Alias**: Multiple configurations of the same provider (`provider "aws" { alias = "west" }`)

### Resources

Resources are the most important element — they describe a piece of infrastructure (an EC2 instance, an S3 bucket, a DNS record).

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name  = "web-server"
    Env   = var.environment
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "my-app-data-${var.environment}"
  force_destroy = true
}
```

- **Syntax**: `resource "<type>" "<local_name>" { ... }`
- **Attributes**: Each resource exposes attributes you can reference: `aws_instance.web.id`
- **Meta-arguments**: `count`, `for_each`, `depends_on`, `provider`, `lifecycle`

### Data Sources

Data sources read information from existing infrastructure not managed by your configuration.

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "from_ami" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_vpc.default.main_route_table_id
  # not really — just for illustration
}
```

- **Syntax**: `data "<type>" "<local_name>" { ... }`
- **Reference**: `data.<type>.<name>.<attribute>`

### Variables

Input variables parameterize your configuration — the **only** way to pass values into a module.

```hcl
# variables.tf
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

variable "cidr_blocks" {
  description = "Allowed CIDR blocks"
  type        = list(string)
}
```

**Variable types**: `string`, `number`, `bool`, `list(<type>)`, `map(<type>)`, `set(<type>)`, `object({...})`, `tuple([...])`, `any`

**Setting variable values**:

```hcl
# terraform.tfvars
environment  = "staging"
instance_type = "t3.medium"
cidr_blocks   = ["10.0.0.0/16"]
```

```bash
# Via CLI
terraform apply -var="environment=prod"
# Via env vars
export TF_VAR_environment=prod
```

### Outputs

Outputs expose information about your infrastructure for use by other configurations, modules, or human consumers.

```hcl
# outputs.tf
output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "instance_public_ip" {
  description = "Public IP of the web instance"
  value       = aws_instance.web.public_ip
  sensitive   = false
}

output "database_password" {
  description = "Master password for RDS"
  value       = aws_db_instance.main.password
  sensitive   = true
}
```

- `sensitive = true` — hides the value in CLI output
- Outputs are shown after `apply` and can be queried with `terraform output`
- Root module outputs become the "return values" of a module when consumed by another config

### State Files

```bash
$ terraform apply
# Creates terraform.tfstate (or writes to remote backend)
```

The state file is a JSON mapping of every resource to its real-world attributes. It is the **sole source of truth** for:

- Resource IDs and attributes
- Dependencies (for parallelism)
- Performance (no API call needed to read existing resources for plan)

### Workspaces

Workspaces let you manage multiple state files for the same configuration — commonly used for environment separation.

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "infra/${terraform.workspace}/terraform.tfstate"
    region = "us-east-1"
  }
}
```

```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
terraform workspace select dev
terraform plan
```

**Workspace commands**:

| Command | Purpose |
|---------|---------|
| `terraform workspace list` | List all workspaces |
| `terraform workspace show` | Show current workspace |
| `terraform workspace new <name>` | Create a new workspace |
| `terraform workspace select <name>` | Switch workspace |
| `terraform workspace delete <name>` | Delete workspace (must be empty) |

**Workspace vs Directory approach**:

| Approach | Pros | Cons |
|----------|------|------|
| **Workspaces** | Single config, simple Git repo | Shared root module, easy to accidentally `apply` to wrong env |
| **Directories** (`envs/dev`, `envs/prod`) | Complete isolation, different versions per env | Code duplication (mitigated by modules) |

### Dependencies

Terraform builds a dependency graph automatically from resource references:

```hcl
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and HTTPS"
  vpc_id      = aws_vpc.main.id  # implicit dependency
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]  # implicit

  depends_on = [aws_cloudwatch_log_group.app]  # explicit
}
```

## Best Practices

1. **Organize files**: `main.tf`, `variables.tf`, `outputs.tf`, `terraform.tf`, `providers.tf`
2. **Pin provider versions** with `~>` constraints
3. **Use `description`** on every variable and output
4. **Prefer data sources** over hardcoding IDs
5. **Validate input variables** with `validation` blocks
6. **Use remote state** with locking for teams
7. **Tag all resources** consistently

## Interview Questions

| Question | Key points |
|----------|------------|
| *What is a Terraform provider?* | Plugin that exposes resources/data sources for an API |
| *Explain implicit vs explicit dependencies* | Implicit from references; explicit with `depends_on` |
| *How do you pass variables to a Terraform config?* | `.tfvars` files, `-var` CLI, `TF_VAR_` env vars |
| *What is `terraform.workspace`?* | The current workspace name, usable in config |
| *What's the difference between `variable` and `output`?* | Input vs output; one parameterizes, the other exposes |
| *What happens if you delete a state file?* | Terraform loses all knowledge of resources; they become orphaned |

---

**Next**: [03 — Terraform Workflow](03-terraform-workflow.md)
