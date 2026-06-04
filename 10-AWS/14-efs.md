# AWS EFS (Elastic File System)

## What is it?
Amazon EFS is a fully managed, scalable, and elastic NFS file system for use with AWS Cloud services and on-premises resources. It automatically scales storage capacity up and down as files are added or removed, with no need for provisioning.

## Why it was created
Shared file storage in the cloud was traditionally complex — you had to provision an NFS server, manage capacity, handle replication, and deal with throughput limits. EFS was created to provide a serverless, elastic file system that multiple EC2 instances can mount simultaneously, with automatic scaling and high durability.

## When should you use it
- **Shared content repositories**: Code repositories, configuration files, and libraries shared across instances
- **Content management systems**: WordPress, Drupal, or custom CMS with shared file storage
- **Big data & analytics**: Shared working storage for EMR, Spark, or data science workloads
- **Container storage**: Persistent volumes for ECS and EKS (via CSI driver)
- **Lift-and-shift migrations**: Migrate on-premises NFS workloads without restructuring

## Architecture

```mermaid
graph TD
    subgraph "EFS Performance Modes"
        GP[General Purpose<br/>Low latency, <7000 ops/sec]
        MAXIO[Max I/O<br/>High throughput, >7000 ops/sec]
    end

    subgraph "Throughput Modes"
        Bursting[Bursting<br/>Baseline + burst credits]
        Provisioned[Provisioned<br/>Fixed throughput, Independent of size]
        Elastic[Elastic<br/>Auto-scales throughput]
    end

    subgraph "Clients"
        EC2[EC2 Instances]
        ECS[ECS Containers]
        EKS[EKS Pods]
        OnPrem[On-prem via Direct Connect/VPN]
        LW[Lambda (via EFS Access Point)]
    end

    subgraph "Features"
        AP[Access Points<br/>Enforce POSIX user/per-path]
        LM[Lifecycle Management<br/>EFS-IA tier after N days]
        Encrypt[Encryption at rest & transit]
        Replication[Cross-region replication]
    end

    GP --> Bursting
    GP --> Provisioned
    GP --> Elastic
    MAXIO --> Bursting
    MAXIO --> Provisioned
    EC2 --> GP
    ECS --> GP
    EKS --> GP
    OnPrem --> GP
    LW --> GP
    GP --> LM
    GP --> AP
    GP --> Encrypt
    GP --> Replication
```

## Hands-on Example

```bash
# Create EFS file system (encrypted, General Purpose)
aws efs create-file-system \
    --creation-token my-app-fs-$(date +%s) \
    --performance-mode generalPurpose \
    --throughput-mode bursting \
    --encrypted \
    --kms-key-id alias/aws/efs \
    --tags Key=Name,Value=my-app-shared-storage

# Create mount targets in each subnet
aws efs create-mount-target \
    --file-system-id fs-12345678 \
    --subnet-id subnet-abc \
    --security-groups sg-123

aws efs create-mount-target \
    --file-system-id fs-12345678 \
    --subnet-id subnet-def \
    --security-groups sg-123

# Create access point (enforces user/per-path)
aws efs create-access-point \
    --file-system-id fs-12345678 \
    --posix-user Uid=1000,Gid=1000 \
    --root-directory Path=/data,CreationInfo='{OwnerUid=1000,OwnerGid=1000,Permissions=0755}'

# Mount on EC2 instance
sudo mkdir -p /mnt/efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-12345678.efs.us-east-1.amazonaws.com:/ /mnt/efs

# Enable lifecycle management (move to IA after 30 days)
aws efs put-lifecycle-configuration \
    --file-system-id fs-12345678 \
    --lifecycle-policies '[{"TransitionToIA": "AFTER_30_DAYS"}]'
```

## Pricing Model
- **Standard storage**: $0.30/GB per month for EFS Standard
- **EFS-IA (Infrequent Access)**: $0.025/GB per month + $0.01/GB read/write access
- **Throughput**: Bursting mode throughput depends on stored data size; Provisioned mode charges per MB/s
- **Replication**: Charges for replicated storage in the destination region
- **No charge**: For creating file systems, mount targets, or access points

## Best Practices
- **Use General Purpose for most workloads**: Max I/O trades latency for throughput (use only for big data)
- **Use Elastic throughput mode**: Automatically scales throughput with workload (no provisioning)
- **Lifecycle management**: Move inactive files to EFS-IA after 30 days to reduce costs
- **Access Points**: Use APs with ECS/EKS to enforce POSIX user IDs and restrict access to specific paths
- **Encryption**: Enable encryption at rest with KMS for compliance; enforce encryption in transit using client certificates
- **Mount target per AZ**: Create a mount target in each AZ where you run instances for HA
- **Use EFS for persistent volumes in containers**: ECS and EKS both support EFS via CSI driver

## Interview Questions
1. What's the difference between EFS General Purpose and Max I/O performance modes?
2. How does EFS bursting throughput work compared to Provisioned throughput?
3. What are EFS Access Points and when would you use them?
4. How does EFS differ from EBS in terms of multi-instance access?
5. How does EFS lifecycle management help reduce storage costs?

## Real Company Usage
**Twilio** uses EFS as shared storage for their microservices running on ECS, providing consistent file access across containers. **Dow Jones** uses EFS to share configuration and media files across their content publishing platform running on EC2 instances.
