# Notesy Infrastructure

![CI Status](https://img.shields.io/github/actions/workflow/status/gasper-anjanoh-dev/notesy-infrastructure/.github/workflows/iac-pipeline.yml?branch=main)
![Terraform Version](https://img.shields.io/badge/terraform-1.15.5-blue.svg)
![AWS Region](https://img.shields.io/badge/region-us--east--1-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

Production-grade AWS infrastructure for a Django application demonstrating NIST 800-53 aligned CI/CD pipelines, multi-region high availability, four golden signals observability, and zero-downtime deployments. Built as a portfolio project by a cloud infrastructure engineer with 8 years of AWS experience.

Architecture (ASCII)
--------------------

Users → CloudFront CDN → WAF → ALB → ECS Fargate → RDS PostgreSQL / ElastiCache Redis

Route 53 failover → standby region (us-west-2)

```
Users
  |
  v
CloudFront (global CDN)
  |
  v
WAF (edge)
  |
  v
ALB (us-east-1)
  |
  v
ECS Fargate (tasks)
  |    \
  |     \---> ElastiCache Redis
  \---> RDS PostgreSQL (primary)

Route 53
  └─ failover ─> us-west-2 (standby) : ECS, RDS replica, Redis
```

Module structure
----------------

| Module | Purpose |
|--------|---------|
| networking | VPC, subnets, NAT Gateway, routing |
| alb | Application Load Balancer, listeners |
| ecs | ECS cluster, task definition, service, IAM |
| waf | WAF Web ACL, managed rule groups |
| cdn | CloudFront distribution |
| rds | RDS PostgreSQL, Secrets Manager |
| redis | ElastiCache Redis |
| autoscaling | ECS target tracking policies |
| monitoring | CloudWatch dashboard, alarms, SNS |

Environments
------------

| Environment | Region | Purpose | Applied |
|-------------|--------|---------|---------|
| dev | us-east-1 | Full stack development | Yes |
| staging | us-east-1 | Demo only, never applied | No |
| prod-west | us-west-2 | Standby region | Plan only |

NIST 800-53 Controls
---------------------

| Control | Description | Implementation |
|---------|-------------|----------------|
| CM-3 | Change Control | Manual approval gates (plan & apply) |
| AC-6 | Least Privilege | OIDC (no stored credentials) |
| AU-2 | Audit Events | Full pipeline logging (GitHub Actions) |
| AU-3 | Audit Content | Terraform plan posted as PR comment |
| RA-5 | Vulnerability Scan | tfsec run before plan |
| CA-7 | Continuous Monitoring | Nightly drift detection (plan -detailed-exitcode) |
| CM-6 | Config Settings | Drift detection baseline & policies |
| SC-28 | Protection at Rest | KMS encryption for RDS / S3 where applicable |

Four Golden Signals
-------------------

| Signal | Metric | Alarm Threshold | Evaluation |
|--------|--------|-----------------|------------|
| Latency | ALB TargetResponseTime | > 2s | 2 periods |
| Traffic | ALB RequestCount | Visibility only | — |
| Errors | ALB 5XX Count | > 10 in 5 min | 3 periods |
| Saturation | ECS CPU | > 80% for 10 min | 2 periods |

Pipeline flow
-------------

PR opened → Approval gate 1 → tfsec security scan → Terraform plan → Plan posted as PR comment → Merge to main → Approval gate 2 → Terraform apply (dev only).

Nightly: drift detection via scheduled cron using `terraform plan -detailed-exitcode` to detect out-of-band changes (CA-7).

Key features
------------

- Zero stored AWS credentials (OIDC federation)
- Terraform plan reviewed before every apply
- Two manual approval gates per deployment
- Nightly drift detection (NIST CA-7)
- Multi-region standby architecture (prod-west)
- Four golden signals with CloudWatch dashboard
- Auto scaling: min 1, max 10 ECS tasks
- RDS Multi-AZ with automated backups (configurable)
- Secrets Manager for all sensitive values
- WAF with managed rule groups at CloudFront edge

Quick start
-----------

Prerequisites

- AWS CLI configured
- Terraform 1.15.5
- Git and a GitHub account

Local quickstart

```bash
# Clone
git clone https://github.com/gasper-anjanoh-dev/notesy-infrastructure.git
cd notesy-infrastructure

# Configure backend S3/DynamoDB in environments/dev/backend.tf and provide your account id
cd environments/dev
terraform init
terraform plan
terraform apply
```

Destroy

```bash
cd environments/dev
terraform destroy
```

Cost
----

Estimated running cost (approx): ~$2.70/day

Rough breakdown:

- NAT Gateway: ~$1/day
- ALB: ~$0.60/day
- ECS tasks (small): ~$0.30/day (varies with CPU/memory)
- RDS (db.t3.micro with storage): ~$0.50/day (depends on instance class)

Tip: destroy environments when not needed. Re-deploy typically completes within ~15 minutes.

Portfolio note
--------------

This project was built to demonstrate production-grade infrastructure engineering patterns including NIST 800-53 compliance, GitOps workflows, and AWS best practices. It has been cloned by 75+ engineers in its first two weeks as a public repository.

Links

- notesy-app: https://github.com/gasper-anjanoh-dev/notesy-app
- Author GitHub: https://github.com/gasper-anjanoh-dev
- Author LinkedIn: https://www.linkedin.com/in/gasper-anjanoh-dev

License
-------

MIT License

---

If you want this README tailored with your real LinkedIn URL, cost estimates adjusted for chosen instance sizes, or embedded diagrams (SVG/PNG), tell me which details to adjust and I will update it.
