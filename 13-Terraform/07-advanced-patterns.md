# 07 — Advanced Patterns

## What is it?

Beyond basic resources and modules, Terraform offers a set of powerful metalinguistic features that let you write dynamic, reusable, and maintainable configurations. These patterns — `count`, `for_each`, `dynamic` blocks, `locals`, `depends_on`, provisioners, `moved`, and refactoring tools — distinguish beginner from advanced Terraform practitioners.

## Why it matters

Real-world infrastructure is rarely static. You need to create variable numbers of resources, conditionally include features, iterate over complex data structures, and safely refactor configurations over time. These patterns make your code DRY, flexible, and production-ready.

## `count` vs `for_each`

### `count` — Create N resources

```hcl
variable "subnet_cidrs" {
  description = "CIDR blocks for subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

resource "aws_subnet" "main" {
  count = length(var.subnet_cidrs)

  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "subnet-${count.index + 1}"
  }
}
```

**Downside of `count`**: If you remove an element from the middle of the list, `count.index` shifts and Terraform recreates resources. Use `count` only when resources are **identical** indexed by number.

### `for_each` — Create resources from a map or set

```hcl
# Using for_each with a map
variable "subnets" {
  description = "Subnet configuration"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "subnet-a" = { cidr = "10.0.1.0/24", az = "us-east-1a" }
    "subnet-b" = { cidr = "10.0.2.0/24", az = "us-east-1b" }
  }
}

resource "aws_subnet" "main" {
  for_each = var.subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = each.key
  }
}

# Access using each.key and each.value
output "subnet_ids" {
  value = { for k, v in aws_subnet.main : k => v.id }
}
```

**With `for_each`**:
- Using a **map**: each item is identified by its key; removing one key doesn't affect others
- Using a **set of strings**: `for_each = toset(["a", "b", "c"])`
- Each resource is addressable as `aws_subnet.main["subnet-a"]`
- The `each` object has `each.key` and `each.value`

### When to use which

| Scenario | Use |
|----------|-----|
| N resources of same type, indexed by number | `count` |
| Resources backed by items in a map/set | `for_each` |
| Resources keyed by a unique identifier | `for_each` |
| Resources conditional on a boolean | `count = var.enabled ? 1 : 0` |
| Need stable addressing across changes | `for_each` |

## `dynamic` Blocks

Many Terraform resources accept repeatable nested blocks (e.g., `ingress` in `aws_security_group`, `logging` in `aws_s3_bucket`). `dynamic` blocks let you generate these programmatically.

```hcl
# Dynamic security group rules
variable "ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
  ]
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group with dynamic rules"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

```hcl
# Dynamic logging configuration for S3
variable "logging" {
  type = object({
    enabled = bool
    bucket  = string
    prefix  = optional(string, "")
  })
  default = null
}

resource "aws_s3_bucket" "data" {
  bucket = "my-app-data"

  dynamic "logging" {
    for_each = var.logging != null && var.logging.enabled ? [var.logging] : []
    content {
      target_bucket = logging.value.bucket
      target_prefix = logging.value.prefix
    }
  }
}
```

## Local Values

`locals` let you define named expressions that you can reference multiple times — they're constants in Terraform.

```hcl
locals {
  # Computed name prefix
  name_prefix = "${var.project_name}-${var.environment}"

  # Common tags merged with environment-specific tags
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Name        = local.name_prefix
    }
  )

  # CIDR blocks calculated from a base
  public_subnet_cidrs  = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnet_cidrs = [for i in range(2, 4) : cidrsubnet(var.vpc_cidr, 8, i)]

  # Only create NAT gateway in non-prod
  enable_nat = var.environment != "prod" ? false : true

  # Instance type based on environment
  instance_type = var.environment == "prod" ? "t3.large" : "t3.medium"
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = local.instance_type

  tags = local.common_tags
}
```

## Data Sources for Advanced Lookups

```hcl
# Look up the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Look up existing VPC by tag
data "aws_vpc" "selected" {
  tags = {
    Environment = var.environment
    Type        = "main"
  }
}

# Look up subnets by filter
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    Tier = "private"
  }
}

# Get the current caller identity
data "aws_caller_identity" "current" {}

# Get current region
data "aws_region" "current" {}

# Use: data.aws_caller_identity.current.account_id
# Use: data.aws_region.current.name
```

## `depends_on` (Explicit Dependencies)

Terraform automatically detects most dependencies from attribute references. Use `depends_on` only when there's no data reference but an ordering constraint exists.

```hcl
# Bad — implicit dependency from subnet_id reference
resource "aws_instance" "web" {
  subnet_id = aws_subnet.public[0].id  # automatic
}

# Necessary explicit dependency (no attribute reference)
resource "aws_iam_role_policy_attachment" "web_policy" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "web" {
  name = "web-profile"
  role = aws_iam_role.web.name
  depends_on = [aws_iam_role_policy_attachment.web_policy]
  # Explicit — IAM propagation takes time
}
```

## Provisioners

Provisioners run scripts or commands on resources after creation. They are a **last resort** — prefer user data, custom images, or configuration management tools.

```hcl
# local-exec — runs on the machine running Terraform
resource "null_resource" "provisioner_example" {
  provisioner "local-exec" {
    command = "echo ${aws_instance.web.private_ip} >> inventory.txt"
  }
}

# file — copies files to the resource
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t2.micro"

  provisioner "file" {
    source      = "config/app.conf"
    destination = "/etc/myapp/app.conf"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}

# remote-exec — runs commands on the resource
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t2.micro"

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}
```

**⚠ Provisioner warnings**:
- `destroy` provisioners: use `when = destroy`
- Provisioners are not tracked in state for drift
- `null_resource` + triggers is a common pattern to force re-execution

## `terraform_data` Resource

Replaces the deprecated `null_resource` with a cleaner mechanism for value tracking:

```hcl
resource "terraform_data" "replacement" {
  # When this changes, anything depending on it is replaced
  input = var.ami_id
}

resource "aws_instance" "web" {
  ami           = terraform_data.replacement.input
  instance_type = "t2.micro"
}

resource "null_resource" "run_on_change" {
  triggers = {
    version = var.config_version
  }

  provisioner "local-exec" {
    command = "echo 'Config changed to ${var.config_version}'"
  }
}
```

## `moved` Blocks — Refactoring

The `moved` block lets you rename or restructure resources without destroying and recreating them.

```hcl
# Before: resource was called "aws_instance.web_server"
# After:  renamed to "aws_instance.web"
moved {
  from = aws_instance.web_server
  to   = aws_instance.web
}

# Module refactoring
# Before: resource was in root module
# After:  resource is in module "compute"
moved {
  from = aws_instance.web
  to   = module.compute.aws_instance.web
}

# Refactoring from count to for_each
moved {
  from = aws_subnet.main[0]
  to   = aws_subnet.main["subnet-a"]
}
moved {
  from = aws_subnet.main[1]
  to   = aws_subnet.main["subnet-b"]
}
```

## Refactoring Patterns

### Extract resources into a module

```hcl
# Before (in root module):
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t2.micro"
}

# After (with moved block in root):
moved {
  from = aws_instance.web
  to   = module.compute.aws_instance.web
}

module "compute" {
  source = "./modules/compute"
  ami    = var.ami_id
}
```

### Split a module

```hcl
# Module "network" created VPC and subnets together.
# We split into "vpc" and "subnet" modules.
moved {
  from = module.network.aws_vpc.main
  to   = module.vpc.aws_vpc.main
}

moved {
  from = module.network.aws_subnet.public
  to   = module.subnet.aws_subnet.public
}

module "vpc" {
  source = "./modules/vpc"
}

module "subnet" {
  source  = "./modules/subnet"
  vpc_id  = module.vpc.vpc_id
}
```

## Best Practices

1. **Prefer `for_each` over `count`** when resources have distinct identities
2. **Use `locals`** for computed values reused in multiple places
3. **Prefer user data over provisioners** — it's tracked and doesn't depend on SSH
4. **Use `moved` blocks** for refactoring, never manually edit state
5. **Add `lifecycle` rules** to protect critical resources (`prevent_destroy`)
6. **Keep `dynamic` blocks simple** — if it's too complex, consider a module

## Interview Questions

| Question | Key points |
|----------|------------|
| *Difference between `count` and `for_each`?* | `count` is integer-indexed; `for_each` is keyed from map/set — safer for reordering |
| *When would you use a `dynamic` block?* | When nested blocks must be generated from variable lists |
| *What's the problem with provisioners?* | Not tracked in state; SSH dependencies; last resort only |
| *How do you safely rename a resource?* | `moved` block maps old address to new address |
| *What is a `terraform_data` resource?* | Holds arbitrary data; can trigger side effects on change |
| *What's `prevent_destroy`?* | Lifecycle meta-argument to block accidental deletion |

---

**Next**: [08 — Terraform Cloud](08-terraform-cloud.md)
