# VPC & Networking

## VPC Concepts

```
┌──────────────────────────────────┐
│          VPC (10.0.0.0/16)       │
│                                  │
│  ┌────────────────────────┐     │
│  │  Public Subnet          │     │
│  │  10.0.1.0/24           │     │
│  │  ┌────┐ ┌────┐         │     │
│  │  │NAT │ │ALB │         │     │
│  │  │GW  │ │    │         │     │
│  │  └────┘ └────┘         │     │
│  └────────────────────────┘     │
│                                  │
│  ┌────────────────────────┐     │
│  │  Private Subnet         │     │
│  │  10.0.2.0/24           │     │
│  │  ┌────┐ ┌────┐         │     │
│  │  │App │ │App │         │     │
│  │  └────┘ └────┘         │     │
│  └────────────────────────┘     │
│                                  │
│  ┌────────────────────────┐     │
│  │  Database Subnet        │     │
│  │  10.0.3.0/24           │     │
│  │  ┌────┐ ┌────┐         │     │
│  │  │RDS │ │RDS │         │     │
│  │  └────┘ └────┘         │     │
│  └────────────────────────┘     │
└──────────────────────────────────┘
```

## Key Components

| Component | Purpose |
|-----------|---------|
| **VPC** | Isolated virtual network |
| **Subnet** | IP range within VPC |
| **Internet Gateway** | Public internet access |
| **NAT Gateway** | Outbound internet for private subnets |
| **Security Group** | Stateful instance-level firewall |
| **NACL** | Stateless subnet-level firewall |
| **VPC Peering** | Connect VPCs |
| **Transit Gateway** | Hub-and-spoke VPC connectivity |

## Interview Questions
1. What's the difference between security groups and NACLs?
2. How do you design a VPC for multi-tier applications?
3. What is VPC peering and when would you use Transit Gateway?
4. How does a NAT Gateway provide internet access to private subnets?
5. Design a network architecture for a multi-region deployment
