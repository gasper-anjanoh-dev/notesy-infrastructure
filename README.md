# notesy-infrastructure
AWS infrastructure for Notesy using Terraform and GitHub Actions
# Notesy Infrastructure

AWS infrastructure for the Notesy application using Terraform and GitHub Actions.

## Architecture

Internet → CloudFront CDN → WAF → ALB → ECS Fargate → App

## Tech Stack

- IaC: Terraform
- Cloud: AWS us-east-1
- Containers: ECS Fargate
- CDN: CloudFront
- Security: WAF, IAM, Secrets Manager
- CI/CD: GitHub Actions
- State: S3 + DynamoDB

## Environments

| Environment | Apply | Purpose |
|---|---|---|
| dev | On merge to main | Development and testing |
| staging | Plan only | Pre-production validation |

## NIST 800-53 Controls

| Control | Implementation |
|---|---|
| CM-3 | Manual approval gate before plan triggers |
| AC-6 | OIDC IAM no long-lived access keys |
| AU-2/AU-3 | GitHub Actions audit trail |
| CM-6 | Drift detection via scheduled nightly plan |
| RA-5 | tfsec scanning in pipeline |

## Module Structure

modules/networking - VPC subnets routing
modules/ecs - ECS cluster task definition service
modules/alb - Application Load Balancer
modules/waf - Web Application Firewall rules
modules/cdn - CloudFront distribution

environments/dev - Dev environment plan and apply
environments/staging - Staging environment plan only

## Remote State

- S3 Bucket: notesy-terraform-state-797855613035
- DynamoDB Table: notesy-terraform-locks
- Region: us-east-1
