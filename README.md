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

## Cost

Estimated running cost (approx): ~$2.70/day

Rough breakdown:

- NAT Gateway: ~$1/day
- ALB: ~$0.60/day
- ECS tasks (small): ~$0.30/day (varies with CPU/memory)
- RDS (db.t3.micro with storage): ~$0.50/day (depends on instance class)

Tip: destroy environments when not needed. Re-deploy typically completes within ~15 minutes.

## Portfolio note

This project was built to demonstrate production-grade infrastructure engineering patterns including NIST 800-53 compliance, GitOps workflows, and AWS best practices. It has been cloned by 75+ engineers in its first two weeks as a public repository.

## Links

- notesy-app: [github.com/gasper-anjanoh-dev/notesy-app](https://github.com/gasper-anjanoh-dev/notesy-app)
- Author GitHub: [github.com/gasper-anjanoh-dev](https://github.com/gasper-anjanoh-dev)
- Author LinkedIn: [Gasper Anjanoh — LinkedIn](https://www.linkedin.com/in/gasper-anjanoh-34320147/)

## License

MIT License

---

If you want this README tailored with your real LinkedIn URL, cost estimates adjusted for chosen instance sizes, or embedded diagrams (SVG/PNG), tell me which details to adjust and I will update it.
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
## Cost

Estimated running cost (approx): ~$2.70/day

Rough breakdown:

- NAT Gateway: ~$1.00/day
- ALB: ~$0.60/day
- RDS (db.t3.micro): ~$0.80/day
- ElastiCache (cache.t3.micro): ~$0.50/day
- ECS Fargate (1 task): ~$0.05/hour
- Total: ~$2.70/day when running

Tip: destroy environments when not needed. Re-deploy typically completes within ~15 minutes.

## Portfolio note

This project was built to demonstrate production-grade infrastructure engineering patterns including NIST 800-53 compliance, GitOps workflows, and AWS best practices. It has been cloned by 75+ engineers in its first two weeks as a public repository.

This repository has been cloned by 75+ unique engineers in its first two weeks as a public repository.

## Links

- notesy-app: https://github.com/gasper-anjanoh-dev/notesy-app
- Author GitHub: https://github.com/gasper-anjanoh-dev
- Author LinkedIn: https://linkedin.com/in/gasper-anjanoh

## License

MIT License

