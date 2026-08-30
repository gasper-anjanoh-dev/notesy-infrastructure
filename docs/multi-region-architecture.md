Multi-region Architecture (conceptual)

This document explains a simple approach to achieving multi-region high availability for Notesy without deploying DNS failover in this repository. The example uses a primary region (us-east-1) and a standby region (us-west-2) running lighter resources.

1) Why CloudFront alone is not enough for multi-region HA

- CloudFront caches static content globally at edge locations, improving latency for static assets.
- Dynamic requests that require application logic (login, writes, personalized data) are forwarded from edge to the configured origin (the primary CloudFront origin in us-east-1).
- If the primary region fails, CloudFront may serve cached static content for some time, but dynamic requests will fail because the origin is unavailable.
- CloudFront can be configured with multiple origins, but origin failover at the CDN layer is not a full replacement for DNS-level failover because session affinity, SSL certificates, and origin health checks across regions are complex.

2) Route 53 Failover (conceptual, not implemented here)

- Register your custom domain in Route 53 and create two CloudFront distributions (one per region) or have CloudFront distributions with origins in each region.
- Provision an ACM certificate for CloudFront (must be in us-east-1 for CloudFront) and attach it to both distributions.
- Create Route 53 health checks pointing to a health endpoint on the primary ALB (for example, `https://primary-alb.example.com/health/`) with a check interval of 30s.
- Create a primary DNS record (notesy.example.com) using Failover routing policy with the primary target pointing to the primary CloudFront distribution (PRIMARY) and a secondary record pointing to the standby CloudFront distribution (SECONDARY).
- Route 53 will switch to the secondary record when the health check fails the configured number of consecutive checks (for example, 3 checks → ~90 seconds), providing an RTO ~90s.

3) RDS multi-region strategy (conceptual)

- us-east-1: Primary RDS instance with Multi-AZ enabled (synchronous standby in another AZ within the region) for high availability within the region.
- us-west-2: Cross-region read replica (asynchronous). This replica can be promoted manually to become primary during a failover.
- Promotion steps are manual for RDS (5–10 minutes) unless using Aurora Global (which can failover faster but at higher cost).
- RPO depends on replication lag; plan accordingly (replication typically within seconds for low write volume).

4) Why prod-west uses lighter resources

- The standby region runs minimal capacity to reduce cost while remaining ready to scale.
- Example: 1 ECS task (standby) vs 2 tasks in primary; smaller RDS instance class for demo; Redis with single node.
- On failover, infrastructure is scaled up (manually or via automation) to match production demand.
- This keeps standby costs ~40% of primary while providing a recoverable environment when promoted.

Notes and operational considerations

- Keep health-check endpoints lightweight (no heavy DB queries) and return 200 when the app is healthy.
- For transactional guarantees, plan for data replication and backup/restore workflows when promoting replicas.
- Ensure secrets (Secrets Manager) and parameter stores are replicated or available in the standby region.
- Test failover processes regularly in a rehearsed runbook.
