# Azure Policy & Blueprints

## What is it?
Azure Policy is a service for creating, assigning, and managing policies that enforce rules and effects over Azure resources. It evaluates resources for compliance with policy definitions and provides remediation for non-compliant resources. Azure Blueprints (being replaced by Deployment Stacks) enabled orchestrated deployment of policy definitions, role assignments, ARM templates, and resource groups as a single composable artifact.

## Why it was created
Organizations need guardrails to ensure resources comply with corporate standards, security requirements, and regulatory mandates. Without Policy, teams can create resources that violate security rules (e.g., public storage, unencrypted disks, unapproved regions). Azure Policy was created to provide continuous compliance evaluation, enforcement, and automated remediation across the entire Azure environment.

## When should you use it
- **Enforce security baselines**: Require encryption, restrict public endpoints, enforce TLS versions
- **Regulatory compliance**: Meet PCI-DSS, HIPAA, SOC 2, ISO 27001 requirements with built-in initiatives
- **Cost governance**: Restrict expensive VM SKUs, enforce tags for cost allocation
- **Multi-subscription governance**: Apply policies across management groups to enforce organization-wide standards
- **Remediation**: Automatically fix non-compliant resources (e.g., add tags, enable encryption)

## Architecture

```mermaid
graph TB
    subgraph "Policy Definition"
        PD[Policy Definition<br/>e.g., "Allowed Locations"]
        PI[Policy Initiative / Set<br/>e.g., "Security Baseline"]
        EFF[Effects: Deny, Audit, Append, Modify, DeployIfNotExists]
    end
    subgraph "Assignment"
        AS[Assignment<br/>Scope: MG → Subscription → RG]
        EX[Exemptions<br/>Waiver, Mitigated]
        RE[Remediation Task]
    end
    subgraph "Compliance"
        EV[Evaluation - Real-time + Periodic]
        CP[Compliance Dashboard]
        NR[Non-compliant Resources]
    end
    subgraph "Integration"
        MON[Azure Monitor - Alerts]
        LOG[Activity Log - Event History]
        ARG[Resource Graph - Query]
    end
    subgraph "Blueprints / Stacks"
        BF[Blueprint Definition<br/>Policies + Roles + ARM + RG]
        BA[Blueprint Assignment]
        BV[Blueprint Versions]
    end

    PD --> PI
    PI --> AS
    AS --> EV
    EV --> CP
    EV --> NR
    EFF --> PD
    EX --> AS
    RE --> NR
    NR --> MON
    NR --> LOG
    NR --> ARG
    BA --> AS
    BF --> BA
    BF --> BV
```

## Policy Effects

| Effect | Behavior | Use Case |
|--------|----------|----------|
| **Deny** | Blocks resource creation/update that violates policy | Enforce region restrictions, deny public IPs |
| **Audit** | Logs non-compliant resources via Activity Log, allows creation | Identify existing non-compliant resources |
| **Append** | Adds fields to resource during creation (non-existent fields) | Tag enforcement, IP restriction |
| **Modify** | Adds or alters fields on existing resources | Auto-tag resources with compliance tags |
| **DeployIfNotExists** | Deploys a template to remediate non-compliant resources | Auto-enable diagnostics, deploy security agents |
| **Disabled** | Policy rule is ignored | Testing, gradual rollout |

## Policy Definition Examples

```json
{
    "policyRule": {
        "if": {
            "allOf": [
                { "field": "type", "equals": "Microsoft.Compute/virtualMachines" },
                { "field": "Microsoft.Compute/virtualMachines/storageProfile.osDisk.managedDisk.storageAccountType",
                  "notIn": ["StandardSSD_LRS", "Premium_LRS"] }
            ]
        },
        "then": { "effect": "deny" }
    }
}

// Initiative assignment — multiple policies
{
    "properties": {
        "displayName": "Security Baseline Initiative",
        "policyDefinitions": [
            { "policyDefinitionId": "/providers/Microsoft.Authorization/policyDefinitions/...",
              "parameters": { "effect": { "value": "Deny" } } },
            { "policyDefinitionId": "/providers/Microsoft.Authorization/policyDefinitions/...",
              "parameters": { "listOfAllowedLocations": { "value": ["eastus", "westus"] } } }
        ]
    }
}
```

## Remediation

Remediation tasks automatically fix non-compliant resources for policies with **DeployIfNotExists** or **Modify** effects.

```bash
# Create a policy assignment with remediation
az policy assignment create \
    --name "require-sql-encryption" \
    --scope /subscriptions/12345 \
    --policy /providers/Microsoft.Authorization/policyDefinitions/... \
    --mi-system-assigned \
    --location eastus \
    --identity-scope /subscriptions/12345 \
    --role "SQL DB Contributor"

# Create remediation task
az policy remediation create \
    --name "encrypt-sql-dbs" \
    --policy-assignment "require-sql-encryption" \
    --scope /subscriptions/12345

# List non-compliant resources
az policy state list \
    --filter "complianceState eq 'NonCompliant'"

# Trigger compliance scan
az policy state trigger-scan \
    --scope /subscriptions/12345
```

## Blueprints (Legacy — Replaced by Deployment Stacks)

```bash
# Create blueprint definition
az blueprint create \
    --name "Security-Baseline" \
    --scope /subscriptions/12345 \
    --blueprint-file blueprint.json

# Blueprint JSON structure
{
    "properties": {
        "targetScope": "subscription",
        "parameters": { "principalId": { "type": "string" } },
        "resourceGroups": {
            "NetworkRG": { "location": "eastus" },
            "SecurityRG": { "location": "eastus" }
        },
        "blueprintArtifacts": [
            {
                "kind": "policyAssignment",
                "properties": {
                    "displayName": "Deny public storage",
                    "policyDefinitionId": "/providers/...",
                    "parameters": { "effect": { "value": "Deny" } }
                }
            },
            {
                "kind": "roleAssignment",
                "properties": {
                    "displayName": "Network Admin",
                    "roleDefinitionId": "/providers/...",
                    "principalIds": ["[parameters('principalId')]"]
                }
            },
            {
                "kind": "template",
                "properties": {
                    "displayName": "Network Template",
                    "template": { "$schema": "..." }
                }
            }
        ]
    }
}

# Assign blueprint version
az blueprint assignment create \
    --name "assign-security-baseline" \
    --subscription 12345 \
    --blueprint-version "Security-Baseline_v1.0"
```

## Hands-on Example

```bash
# Create custom policy definition
az policy definition create \
    --name "allowed-locations" \
    --display-name "Allowed Locations" \
    --description "Restrict resources to approved Azure regions" \
    --rules '{
        "if": {
            "field": "location",
            "notIn": ["eastus", "westus", "northeurope"]
        },
        "then": { "effect": "deny" }
    }' \
    --mode All

# Create policy initiative
az policy set-definition create \
    --name "compliance-initiative" \
    --display-name "Compliance Initiative" \
    --definitions '[
        {"policyDefinitionId": "/subscriptions/.../providers/.../allowed-locations"}
    ]'

# Assign policy
az policy assignment create \
    --name "enforce-allowed-locations" \
    --scope /providers/Microsoft.Management/managementGroups/MyMG \
    --policy /subscriptions/.../providers/.../compliance-initiative \
    --params '{"listOfAllowedLocations": {"value": ["eastus", "westus"]}}'

# Create exemption
az policy exemption create \
    --name "dev-exemption" \
    --scope /subscriptions/.../resourceGroups/dev \
    --policy-assignment enforce-allowed-locations \
    --exemption-category Waiver \
    --description "Temporary exemption for dev team testing"
```

## Pricing Model

| Component | Pricing |
|-----------|---------|
| **Azure Policy** | Free — no charge for policy definitions, assignments, or compliance evaluation |
| **Blueprints** | Free — no charge for blueprint definition or assignment |
| **Remediation tasks** | No charge for the task; underlying resources (e.g., DeployIfNotExists) billed separately |
| **Resource Graph queries** | Free for standard queries |

## Best Practices
- **Assign policies at management group scope**: Apply organization-wide standards at the highest effective scope
- **Use initiatives (policy sets)**: Group related policies into compliance initiatives (e.g., "PCI-DSS", "Security Baseline")
- **Start with Audit effect**: Audit first to understand compliance posture before enforcing Deny
- **Use DeployIfNotExists for auto-remediation**: Automatically remediate common compliance violations
- **Use Modify effect for tagging**: Auto-apply tags to resources without blocking creation
- **Use exemptions sparingly**: Document and time-limit exemptions for temporary exceptions
- **Monitor compliance dashboard**: Regularly review compliance score and non-compliant resources
- **Export compliance data**: Use Resource Graph to query compliance state for reporting

## Interview Questions
1. What are the policy effects and when would you use each? (Deny, Audit, Append, Modify, DeployIfNotExists)
2. How does Azure Policy differ from Azure RBAC?
3. How does policy evaluation work — when does it evaluate resources?
4. How do policy initiatives help with regulatory compliance (PCI-DSS, HIPAA)?
5. How does remediation work for DeployIfNotExists and Modify effects?
6. How does Azure Policy integrate with Azure Resource Graph for compliance queries?
7. What are the differences between Blueprints and Deployment Stacks?
8. How do exemptions work and when should you use them?

## Real Company Usage
**Microsoft** uses Azure Policy internally to enforce resource governance across all Azure engineering teams, with thousands of policy assignments across management groups. **Coca-Cola** uses Azure Policy initiatives to enforce security and compliance standards across their global Azure footprint. **Maersk** uses Azure Policy with auto-remediation to enforce encryption and logging requirements across their logistics platform.
