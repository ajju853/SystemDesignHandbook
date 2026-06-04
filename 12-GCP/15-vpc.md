# VPC (Virtual Private Cloud)

## What is it?
GCP VPC provides global virtual networking for GCP resources, including subnets, firewalls, routing, NAT, VPN, and Interconnect. Unlike AWS and Azure, GCP VPCs are global resources that span all regions.

## Why it was created
Cloud resources need isolated, configurable network environments with fine-grained access control, connectivity to on-premises networks, and the ability to scale globally without network reconfiguration.

## When should you use it
- Isolating GCP resources in a private network
- Connecting GCP to on-premises via VPN or Interconnect
- Multi-region architectures with a single network
- Microservices communication between GKE, Compute Engine, Cloud Run
- Compliance requirements for network isolation (VPC Service Controls)
- Multi-project networking via Shared VPC or VPC peering

## Architecture

```mermaid
graph TB
    subgraph Organization
        subgraph Host Project (Shared VPC)
            HVPC[Shared VPC]
            HSUB1[Subnet - us-central1]
            HSUB2[Subnet - europe-west1]
        end
        subgraph Service Project 1
            VM[Compute Engine]
            GKE[GKE Cluster]
        end
        subgraph Service Project 2
            CR[Cloud Run]
            PS[Pub/Sub]
        end
    end
    subgraph On-Premises
        VPN[Cloud VPN]
        IC[Cloud Interconnect]
    end
    subgraph External
        NAT[Cloud NAT]
        PSC[Private Service Connect]
    end
    HVPC --- HSUB1
    HVPC --- HSUB2
    HSUB1 --- VM
    HSUB1 --- GKE
    HSUB2 --- CR
    HVPC --- VPN
    HVPC --- IC
    HSUB1 --- NAT
```

## Projects, Networks (Default / Auto / Custom)

| Network Type | Subnets | Use Case |
|--------------|---------|----------|
| **Default** | Pre-created (1 per region) | Getting started, dev/test |
| **Auto** | Auto-created (1 per region) | Simple projects, prototyping |
| **Custom** | User-defined (any CIDR) | Production, controlled environments |

- **Default network**: Created in every new project; includes firewall rules (allow HTTP/HTTPS/SSH)
- **Auto network**: Similar to default but no pre-defined firewall rules
- **Custom network**: Full control; recommended for production

## Subnets
- Global VPC can have subnets in any region
- Subnets are regional resources (span all zones in a region)
- Primary CIDR range + optional secondary CIDR ranges (for GKE pods/services)
- Subnets can be expanded without downtime (if no overlapping routes)
- Max 1000 subnets per VPC

## Firewall Rules
- Stateful firewall (return traffic automatically allowed)
- Rules: direction (ingress/egress), source/destination (CIDR, tags, SA), protocol/port, action (allow/deny)
- Priority: 0 (highest) to 65535 (lowest); default allow egress, deny ingress
- Tags: Apply firewall rules to specific instances (e.g., `http-server`, `ssh-only`)
- Service accounts: Apply firewall rules based on instance's service account

## Cloud NAT
- Managed NAT service for private instances to access internet
- Outbound-only (no inbound connections from internet)
- Supports NAT gateway configurations (manual or auto)
- Per-subnet or per-region allocation
- Required for: private GKE clusters, private VMs pulling images, external API access

## Cloud VPN
- **HA VPN**: 99.99% SLA; supports dynamic routing (BGP); up to 3 Gbps per tunnel
- **Classic VPN**: Static routing; simpler but less reliable
- Use for: connecting on-premises to GCP, connecting to other cloud providers
- Supports IPsec IKEv1 and IKEv2

## Cloud Interconnect

| Type | Bandwidth | SLA | Use Case |
|------|-----------|-----|----------|
| **Dedicated Interconnect** | 10 Gbps or 100 Gbps | 99.99% | High bandwidth, low latency |
| **Partner Interconnect** | 50 Mbps - 10 Gbps | Varies | Smaller connectivity needs |
| **Cross-Cloud Interconnect** | 10-100 Gbps | N/A | Google ↔ AWS/Azure |
| **Carrier Peering** | Up to 10 Gbps | No SLA | Direct peering (non-VPN) |

## VPC Peering
- Connect two VPCs (same or different project/organization)
- No transitive peering (A ↔ B and B ↔ C does not give A ↔ C)
- CIDR ranges must not overlap
- Supports across GCP regions and projects

## Shared VPC
- One host project shares VPC subnets with multiple service projects
- Subnets managed centrally; individual projects deploy resources
- Use for: multi-project enterprise orgs, centralized network teams
- Service projects can't create their own VPCs in host project

## Private Google Access
- VMs with only private IPs can access Google APIs and services (Cloud Storage, BigQuery, etc.)
- Enabled per subnet
- Traffic goes through Google's internal network (not internet)
- Required for: private instances accessing GCP services

## VPC Service Controls
- Perimeter around GCP services to prevent data exfiltration
- Access can be restricted by identity (IAM) and context (device, IP, session)
- Supported by: Cloud Storage, BigQuery, Bigtable, Spanner, Pub/Sub, etc.
- Use for: regulatory compliance (PCI-DSS, HIPAA), sensitive data protection
- Dry-run mode for testing before enforcement

## Packet Mirroring
- Duplicates network traffic for security monitoring and analysis
- Sources: VM instances with specific tags
- Destinations: Network security appliances (e.g., Palo Alto, Check Point)
- Supports ingress/egress filtering
- Can't mirror: Google-managed services, GKE nodes (specific)

## Hands-on Example

```bash
# Create custom VPC
gcloud compute networks create my-vpc \
  --subnet-mode=custom \
  --bgp-routing-mode=regional

# Create subnets
gcloud compute networks subnets create us-subnet \
  --network=my-vpc \
  --region=us-central1 \
  --range=10.0.1.0/24 \
  --secondary-range=pod-range=10.1.0.0/16,svc-range=10.2.0.0/20

gcloud compute networks subnets create eu-subnet \
  --network=my-vpc \
  --region=europe-west1 \
  --range=10.0.2.0/24

# Create firewall rules
gcloud compute firewall-rules create allow-ssh \
  --network=my-vpc \
  --direction=INGRESS \
  --priority=1000 \
  --source-ranges=0.0.0.0/0 \
  --allow=tcp:22 \
  --target-tags=ssh-only

# Create Cloud NAT
gcloud compute routers create nat-router \
  --network=my-vpc \
  --region=us-central1

gcloud compute routers nats create cloud-nat \
  --router=nat-router \
  --region=us-central1 \
  --nat-all-subnet-ip-ranges \
  --auto-allocate-nat-external-ips

# Create HA VPN
gcloud compute vpn-gateways create my-vpn-gw \
  --network=my-vpc \
  --region=us-central1

gcloud compute vpn-tunnels create my-tunnel \
  --region=us-central1 \
  --vpn-gateway=my-vpn-gw \
  --peer-gcp-gateway=ON_PREM_GW \
  --shared-secret=SECRET
```

## Pricing Model
- **VPC networks**: Free (no charge for creating VPCs)
- **Subnets**: Free
- **Firewall rules**: Free (first 100 rules, then $0.10/rule/month over)
- **Cloud NAT**: $0.014 - $0.023/hour per NAT gateway + data processing ($0.012/GB)
- **Cloud VPN**: HA VPN $0.52/hour, Classic VPN $0.26/hour
- **Cloud Interconnect**: Dedicated: $2.50/hour (10 Gbps) or $15/hour (100 Gbps); Partner: varies
- **Packet Mirroring**: $0.50/hour per source NIC + $0.05/GB processed
- **Egress**: Standard data transfer pricing

## Best Practices
- Use custom VPC (not default or auto) for production
- Use Shared VPC for centralized network management in multi-project orgs
- Implement least-privilege firewall rules (deny all ingress, allow specific)
- Use VPC Service Controls for sensitive data (prevent data exfiltration)
- Enable Private Google Access for private VM → GCP API communication
- Use Cloud NAT for private instances needing outbound internet
- Implement HA VPN for production on-premises connectivity
- Use VPC peering for cross-project communication within same org
- Monitor VPC flow logs for network visibility

## Interview Questions
1. How does GCP's global VPC differ from region-scoped VPCs in AWS and Azure?
2. What are the differences between VPC peering and Shared VPC?
3. How does Cloud NAT work and when is it needed?
4. Explain VPC Service Controls and how they prevent data exfiltration
5. Design a multi-region, multi-project VPC architecture with on-premises connectivity

## Real Company Usage
- **Twitter**: Uses GCP Shared VPC for multi-project networking
- **PayPal**: Global VPC architecture across multiple regions for payment processing
- **HSBC**: Shared VPC with VPC Service Controls for regulatory compliance
- **eBay**: Multi-project VPC topology with Cloud Interconnect for hybrid cloud
