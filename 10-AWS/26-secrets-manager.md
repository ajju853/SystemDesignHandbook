# AWS Secrets Manager

## What is it?
AWS Secrets Manager is a fully managed service that helps protect access to your applications, services, and IT resources. It enables you to easily rotate, manage, and retrieve database credentials, API keys, and other secrets throughout their lifecycle.

## Why it was created
Applications need secrets (database passwords, API keys, tokens) but storing them in code, config files, or environment variables is insecure and makes rotation painful. Secrets Manager was created to provide a secure, centralized service for storing, rotating, and auditing secrets with fine-grained access control and automatic rotation.

## When should you use it
- **Database credentials**: Store and automatically rotate RDS, Redshift, DocumentDB passwords
- **API keys**: Store third-party API keys and service tokens
- **OAuth tokens**: Securely store and refresh OAuth access tokens
- **CI/CD secrets**: Inject secrets into build pipelines (CodeBuild, Jenkins, GitHub Actions)
- **Cross-account secrets**: Share secrets across AWS accounts using resource-based policies

## Architecture

```mermaid
graph TD
    subgraph "Secret Sources"
        RDS[RDS - Automatic Rotation]
        Redshift[Redshift - Automatic Rotation]
        DocumentDB[DocumentDB - Automatic Rotation]
        Custom[Custom Secrets - API Keys, Tokens]
    end

    subgraph "Secrets Manager"
        Secret[Secret - Name, Value, Metadata]
        Rotation[Automatic Rotation<br/>Lambda rotation function]
        Version[Versioning<br/>Staging labels (AWSCURRENT, AWSPREVIOUS)]
        Policy[Resource-based Policy<br/>Cross-account access]
        Backup[Backup & Recovery<br/>Multi-region replication]
    end

    subgraph "Integration"
        Lambda[Lambda - Secrets Manager Extension]
        ECS[ECS - Environment Variables / Secrets]
        RDS_Proxy[RDS Proxy - IAM auth + Secrets Manager]
        CF[CloudFormation - Dynamic References]
        CI[CI/CD - CodeBuild, Jenkins]
    end

    subgraph "Access Control"
        IAM[IAM Policies<br/>SecretsManager:GetSecretValue]
        KB[KMS Encryption<br/>AWS-managed or Customer-managed key]
    end

    RDS --> Secret
    Secret --> Rotation
    Secret --> Version
    Secret --> Policy
    Secret --> Backup
    Secret --> IAM
    Secret --> KB
    Secret --> Lambda
    Secret --> ECS
    Secret --> RDS_Proxy
    Secret --> CF
    Secret --> CI
```

## Hands-on Example

```bash
# Create secret (database credentials)
aws secretsmanager create-secret \
    --name production/database/master \
    --description "Production RDS master credentials" \
    --secret-string '{"username":"admin","password":"MyS3cureP@ss!","host":"mydb.abc123.us-east-1.rds.amazonaws.com","port":3306,"dbname":"myapp"}' \
    --kms-key-id alias/aws/secretsmanager

# Retrieve secret value
aws secretsmanager get-secret-value \
    --secret-id production/database/master \
    --query SecretString \
    --output text

# Rotate secret immediately (test rotation)
aws secretsmanager rotate-secret \
    --secret-id production/database/master

# Create secret with automatic rotation (Lambda)
aws secretsmanager rotate-secret \
    --secret-id production/database/master \
    --rotation-lambda-arn arn:aws:lambda:us-east-1:123456789012:function:rotate-mysql-creds \
    --rotation-rules AutomaticallyAfterDays=30

# Use secret in Lambda (Python)
# import boto3
# from botocore.exceptions import ClientError
# import json
#
# def get_secret():
#     session = boto3.session.Session()
#     client = session.client('secretsmanager')
#     try:
#         response = client.get_secret_value(SecretId='production/database/master')
#         return json.loads(response['SecretString'])
#     except ClientError as e:
#         raise e

# Replicate secret to another region
aws secretsmanager replicate-secret-to-regions \
    --secret-id production/database/master \
    --add-replica-regions Region=eu-west-1
```

## Pricing Model
- **Secrets**: $0.40 per secret per month
- **API calls**: $0.05 per 10,000 API calls (GetSecretValue, PutSecretValue, etc.)
- **Rotation**: $0.40 per secret per month (automatic rotation)
- **Replication**: $0.40 per replicated secret per region per month
- **KMS encryption**: $0.03 per 10,000 KMS API requests (if using customer-managed key)

## Comparison: Secrets Manager vs Systems Manager Parameter Store

| Feature | Secrets Manager | Parameter Store |
|---------|----------------|-----------------|
| **Max secret size** | 64 KB | 4 KB (advanced: 8 KB) |
| **Automatic rotation** | Yes (built-in RDS, custom Lambda) | No (must implement yourself) |
| **Cross-account access** | Yes (resource-based policies) | No (IAM only) |
| **Price** | $0.40/secret/month | Free (standard), $0.05/param/month (advanced) |
| **Generation** | Random password generation | No generation |
| **KMS integration** | Required (uses CMK) | Optional |

## Best Practices
- **Use Secrets Manager for RDS credentials**: Automatic rotation every 30 days with built-in Lambda rotation functions
- **Use Parameter Store for non-sensitive config**: Application configuration strings, feature flags, environment settings
- **Least privilege IAM**: Grant only `secretsmanager:GetSecretValue` on specific secrets
- **Cache secrets in Lambda**: Use the Secrets Manager Lambda Extension for efficient caching (reduces cost and latency)
- **Use version staging labels**: `AWSCURRENT`, `AWSPREVIOUS`, `AWSPENDING` for controlled rotation
- **CloudTrail auditing**: Monitor all `GetSecretValue` and `PutSecretValue` calls for security analysis
- **Replicate cross-region for DR**: Keep synchronized copies of critical secrets in secondary regions

## Interview Questions
1. How does Secrets Manager differ from Systems Manager Parameter Store?
2. How does automatic secret rotation work with Lambda?
3. How would you securely inject database credentials into an ECS task?
4. How do you share secrets across AWS accounts?
5. What are the version staging labels in Secrets Manager and how are they used?

## Real Company Usage
**Dow Jones** uses Secrets Manager to rotate database credentials across their publishing platform, ensuring compliance with their security policy of 30-day rotation. **GoDaddy** uses Secrets Manager with the Lambda extension to cache secrets for their serverless microservices, reducing both latency and API costs.
