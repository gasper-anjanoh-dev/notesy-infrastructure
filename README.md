# Notesy Infrastructure

AWS infrastructure for the Notesy application using Terraform and GitHub Actions.

## Architecture

Internet -> CloudFront CDN -> WAF -> ALB -> ECS Fargate -> App

## Tech Stack

- IaC: Terraform
- Cloud: AWS us-east-1
- Containers: ECS Fargate
- CDN: CloudFront
- Security: WAF, IAM, Secrets Manager
- CI/CD: GitHub Actions with OIDC
- State: S3 + DynamoDB

## Folder Structure

    notesy-infrastructure/
    ├── .github/
    │   └── workflows/
    │       └── iac-pipeline.yml    # IaC pipeline with approval gates
    ├── modules/
    │   ├── networking/             # VPC, subnets, IGW, NAT, routing
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   ├── alb/                    # Application Load Balancer
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   ├── ecs/                    # ECS cluster, task/service, task definition, IAM
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   ├── waf/                    # WAF Web ACL, managed rules
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   ├── cdn/                    # CloudFront distribution
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   ├── rds/                    # RDS PostgreSQL, secrets in Secrets Manager
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   ├── redis/                  # ElastiCache Redis
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   ├── autoscaling/            # ECS target-tracking policies
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   └── monitoring/             # CloudWatch dashboards and alarms
    │       ├── main.tf
    │       ├── variables.tf
    │       └── outputs.tf
    ├── environments/
    │   ├── dev/                    # Dev environment - plan and apply
    │   │   ├── backend.tf          # S3 remote state config
    │   │   ├── main.tf             # Calls all modules
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   └── staging/                # Staging - plan only, never apply
    │       ├── backend.tf
    │       ├── main.tf
    │       ├── variables.tf
    │       └── outputs.tf
    │   └── prod-west/              # Standby region (us-west-2) - plan only
    │       ├── backend.tf
    │       ├── main.tf
    │       ├── variables.tf
    │       └── terraform.tfvars (gitignored local)
    ├── .gitignore
    └── README.md

## Environments

| Environment | Terraform Apply | Purpose |
|---|---|---|
| dev | On merge to main after approval | Development and testing |
| staging | Never - plan only | Pre-production validation (demo only) |
| prod-west | Plan only (standby) | Secondary region (us-west-2) - lighter resources; used for DR demos and testing |

**Important**: This repository only applies changes to the `dev` environment. The `staging` folder is for validation and demos only — do not run `terraform apply` against `environments/staging` in this account. See [environments/staging/DO_NOT_APPLY.md](environments/staging/DO_NOT_APPLY.md) for details.

## Pipeline Flow

    PR opened
        |
        v
    [Manual Approval Gate 1] - CM-3
    Reviewer approves in GitHub
        |
        v
    Security Scan - tfsec - RA-5
        |
        v
    Terraform Plan DEV + STAGING in parallel
    Plan output posted as PR comment - AU-3
        |
        v
    PR merged to main
        |
        v
    [Manual Approval Gate 2] - CM-3
    Reviewer approves apply
        |
        v
    Terraform Apply DEV only
    STAGING never gets applied

## NIST 800-53 Controls

| Control | Description | Implementation |
|---|---|---|
| CM-3 | Configuration Change Control | Manual approval gate before plan and before apply |
| AC-6 | Least Privilege | OIDC federation - no long-lived AWS access keys |
| AU-2 | Audit Events | GitHub Actions logs every run with identity and timestamp |
| AU-3 | Audit Record Content | Terraform plan posted as PR comment before any apply |
| CM-6 | Configuration Settings | Terraform enforces baseline - drift detection nightly |
| RA-5 | Vulnerability Scanning | tfsec scans Terraform code before plan runs |
| CA-7 | Continuous Monitoring | Scheduled nightly plan detects configuration drift |

## Remote State

| Resource | Value |
|---|---|
| S3 Bucket | notesy-terraform-state-797855613035 |
| DynamoDB Table | notesy-terraform-locks |
| Region | us-east-1 |
| Dev State Key | dev/terraform.tfstate |
| Staging State Key | staging/terraform.tfstate |

## Setup Guide

### Prerequisites

- AWS account
- GitHub account
- Terraform >= 1.0 installed locally
- AWS CLI configured locally

### Step 1 - Create S3 Remote State Bucket

    aws s3api create-bucket \
      --bucket notesy-terraform-state-YOURACCOUNTID \
      --region us-east-1

    aws s3api put-bucket-versioning \
      --bucket notesy-terraform-state-YOURACCOUNTID \
      --versioning-configuration Status=Enabled

    aws s3api put-bucket-encryption \
      --bucket notesy-terraform-state-YOURACCOUNTID \
      --server-side-encryption-configuration '{
        "Rules": [{
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          }
        }]
      }'

### Step 2 - Create DynamoDB Lock Table

    aws dynamodb create-table \
      --table-name notesy-terraform-locks \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --region us-east-1

### Step 3 - Set Up OIDC for GitHub Actions

OIDC allows GitHub Actions to authenticate to AWS without storing long-lived access keys. No credentials are stored in GitHub — only a role ARN which is a resource identifier not a secret.

    # Create OIDC provider
    aws iam create-open-id-connect-provider \
      --url https://token.actions.githubusercontent.com \
      --client-id-list sts.amazonaws.com \
      --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

    # Create IAM role
    aws iam create-role \
      --role-name notesy-github-actions-role \
      --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Principal": {
              "Federated": "arn:aws:iam::YOURACCOUNTID:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
              "StringEquals": {
                "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
              },
              "StringLike": {
                "token.actions.githubusercontent.com:sub": "repo:YOURGITHUBUSERNAME/notesy-infrastructure:*"
              }
            }
          }
        ]
      }'

    # Attach permissions
    aws iam attach-role-policy \
      --role-name notesy-github-actions-role \
      --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

### Step 4 - Add GitHub Secret

    Repository Settings -> Secrets and variables -> Actions
    -> New repository secret

    Name:  AWS_ROLE_ARN
    Value: arn:aws:iam::YOURACCOUNTID:role/notesy-github-actions-role

    Note: This is not a credential.
    It is a resource identifier and is safe to store.

### Step 5 - Create GitHub Environments

    Repository Settings -> Environments -> New environment

    Environment 1:
      Name: plan-approval
      Required reviewers: your GitHub username

    Environment 2:
      Name: apply-approval
      Required reviewers: your GitHub username

### Step 6 - Update Backend Config

In environments/dev/backend.tf and environments/staging/backend.tf
replace the bucket name and account ID with yours.

### Step 7 - Test Locally

    cd environments/dev
    terraform init
    terraform plan

## Cost Management

Resources cost money while running.
Create when needed, destroy when done.

    # Deploy
    cd environments/dev
    terraform init
    terraform apply

    # Destroy when done
    terraform destroy

Expensive resources to watch:
- NAT Gateway approximately 1 dollar per day
- ALB approximately 0.60 dollars per day
- ECS tasks approximately 0.04 dollars per hour per vCPU

## Deployed (dev)

The `dev` environment is deployed in AWS (us-east-1) for testing. You can reach the application through the CloudFront distribution which fronts the ALB.

- CloudFront URL: https://d2ficd3btkmau8.cloudfront.net
- ALB DNS name: notesy-dev-alb-1393659005.us-east-1.elb.amazonaws.com

## Observability - Four Golden Signals

| Signal | Metric | Alarm Threshold | Why |
|---|---:|---|---|
| Latency | TargetResponseTime (ALB) | P99 > 2s (alarm: notesy-{env}-latency-high) | User experience degradation |
| Traffic | RequestCount (ALB) | No alarm (dashboard only) | Baseline visibility to correlate spikes |
| Errors | HTTPCode_Target_5XX_Count (ALB) | > 10 errors in 5 min (notesy-{env}-error-rate-high) | Application/infrastructure failure |
| Saturation | CPU/Memory (ECS) | >80% for 10 min (notesy-{env}-cpu-high / memory-high) | Auto scaling target is 70% — 80% means scaling not keeping up |

## Auto scaling

- Minimum tasks: 1 (always one running)
- Maximum tasks: 10 (cost control)
- Scale out trigger: CPU > 70%
- Scale in trigger: CPU < 30%
- Zero downtime: `minimum_healthy_percent = 100`

## False positive avoidance

- Use longer `evaluation_periods` for noisy metrics (errors, latency) to avoid alert storms during deployments.
- Fire immediately for critical alarms (ALB healthy hosts < 1) with `evaluation_periods = 1`.
- Where possible, use `period` aligned with aggregation window (e.g., 300s) for saturation alarms so they reflect sustained behaviour.

## Multi-region diagram

```
  Users Globally
    |
  CloudFront CDN
  (global edge)
    |
   Route 53 DNS
  (failover routing)
     /                \
us-east-1          us-west-2
PRIMARY            STANDBY
2 ECS tasks        1 ECS task
RDS primary        RDS replica
ElastiCache        ElastiCache
     \                /
  CloudFront (same distribution
  serves both regions via
  separate origins)
```

See `docs/multi-region-architecture.md` for a conceptual write-up on Route 53 failover, RDS strategies, and operational notes.

If you see a 302 redirect to `/login/?next=/` that indicates the Django app is running and redirecting unauthenticated requests to the login page.

Note: `staging` is configured for plan-only validation and is not automatically applied in this repository.
