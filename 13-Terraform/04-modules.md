# 04 — Terraform Modules

## What is it?

A Terraform module is a self-contained collection of `.tf` files that defines a piece of infrastructure. **Every Terraform configuration is a module** — the root module is simply the one you run `terraform apply` from. Child modules are called by the root module to compose infrastructure from reusable, versioned building blocks.

## Why it matters

Modules are the primary mechanism for:
- **Reusability** — Write once, use across environments and projects
- **Abstraction** — Hide complexity behind a clean interface (inputs → outputs)
- **Consistency** — Standard VPC, database, or Kubernetes module used everywhere
- **Versioning** — Pin to specific module versions for stability

## Module Structure

```
modules/
├── vpc/
│   ├── main.tf          # Resource definitions
│   ├── variables.tf     # Input variables
│   ├── outputs.tf       # Output values
│   └── README.md        # Documentation
├── ec2/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── rds/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

### Root Module (calling code)

```
infrastructure/
├── main.tf          # Calls child modules
├── variables.tf     # Root-level variables
├── outputs.tf       # Root-level outputs
├── terraform.tf     # Provider and backend config
└── terraform.tfvars # Variable values
```

## Module Inputs & Outputs

### Variable Definitions (`variables.tf`)

```hcl
# modules/vpc/variables.tf
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
```

### Output Definitions (`outputs.tf`)

```hcl
# modules/vpc/outputs.tf
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ips" {
  description = "Elastic IPs of NAT gateways"
  value       = aws_eip.nat[*].public_ip
}
```

### Calling a Module (`main.tf`)

```hcl
# infrastructure/main.tf
module "vpc" {
  source = "../modules/vpc"
  # or: source = "terraform-aws-modules/vpc/aws" # from registry

  vpc_cidr             = "10.0.0.0/16"
  name                 = "myapp-${var.environment}"
  enable_dns_hostnames = true
  tags                 = var.tags
}

module "web_server" {
  source = "../modules/ec2"

  name         = "web-${var.environment}"
  subnet_id    = module.vpc.public_subnet_ids[0]
  vpc_id       = module.vpc.vpc_id
  instance_type = var.instance_type
}

module "database" {
  source = "../modules/rds"

  name         = "db-${var.environment}"
  subnet_ids   = module.vpc.private_subnet_ids
  vpc_id       = module.vpc.vpc_id
  db_password  = var.db_password
}
```

### Module Sources

```
# Local path
source = "../modules/vpc"

# Terraform Registry
source = "terraform-aws-modules/vpc/aws"
source = "hashicorp/consul/aws"

# Git repository
source = "git::https://github.com/org/repo.git//modules/vpc?ref=v1.2.0"

# HTTP URL
source = "https://example.com/modules/vpc.tar.gz"

# S3
source = "s3::https://s3-eu-west-1.amazonaws.com/bucket/modules/vpc.zip"
```

## Version Constraints

```hcl
# Module version from registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "myapp"
  cidr = "10.0.0.0/16"
  azs  = ["us-east-1a", "us-east-1b"]
}

# Git with tag
module "vpc" {
  source = "git::https://github.com/org/terraform-aws-vpc.git?ref=v5.1.0"
}
```

## Module Composition

Modules can call other modules (nested modules). A common pattern is an "infrastructure module" that composes VPC, EC2, RDS, and networking modules:

```
infrastructure/
├── main.tf              # Calls the app module
└── terraform.tfvars

modules/
├── app/
│   ├── main.tf           # Orchestrates vpc + ec2 + rds
│   ├── variables.tf
│   └── outputs.tf
├── vpc/
├── ec2/
└── rds/
```

```hcl
# modules/app/main.tf — composition module
module "vpc" {
  source  = "../vpc"
  name    = var.name
  cidr    = var.vpc_cidr
}

module "web" {
  source    = "../ec2"
  name      = "${var.name}-web"
  subnet_id = module.vpc.public_subnet_ids[0]
  vpc_id    = module.vpc.vpc_id
}

module "db" {
  source    = "../rds"
  name      = "${var.name}-db"
  subnet_ids = module.vpc.private_subnet_ids
  vpc_id    = module.vpc.vpc_id
}

output "web_ip" {
  value = module.web.public_ip
}
```

## Terraform Registry

The [Terraform Registry](https://registry.terraform.io/) hosts public modules:

- **Verified modules** — Published by HashiCorp or partners, extensively tested
- **Community modules** — Published by the community
- **Private registry** — Available in Terraform Cloud / Enterprise

```hcl
# Using a verified module from the registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.17.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Environment = "dev"
  }
}
```

## Publishing a Module

Requirements for publishing a module:
1. Must be a Git repository (GitHub, GitLab, Bitbucket)
2. Follow naming convention: `terraform-<PROVIDER>-<NAME>`
3. Include `README.md`, `main.tf`, `variables.tf`, `outputs.tf`
4. Add tags for versioning: `v1.0.0`, `v1.1.0`

## Best Practices

1. **One concern per module** — A VPC module should not also create EC2 instances
2. **Always add `description`** to every variable and output
3. **Set defaults** where sensible, but never for sensitive values
4. **Expose outputs** for all important resource attributes
5. **Version your modules** with Git tags
6. **Use `source` with `version`** constraints when using registry modules
7. **Test modules** with Terratest or `terraform test`
8. **Document modules** with `README.md` including usage examples

## Interview Questions

| Question | Key points |
|----------|------------|
| *What is a Terraform module?* | A self-contained directory of `.tf` files with inputs and outputs |
| *How do you call a module from a registry?* | `source = "namespace/name/provider"` with `version` |
| *How do you pass values between modules?* | Module outputs consumed as `module.X.attribute` |
| *What's the root module?* | The directory where you run `terraform apply` |
| *Can a module call another module?* | Yes — module composition is a key pattern |
| *How do you version a module?* | Git tags (`v1.0.0`) + `version` constraint in calling code |

---

**Next**: [05 — State Management](05-state-management.md)
