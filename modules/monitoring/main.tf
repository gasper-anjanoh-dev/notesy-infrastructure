resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

locals {
  alb_dimensions = [{ Name = "LoadBalancer", Value = var.alb_name }]
  tg_dimensions  = [{ Name = "TargetGroup", Value = var.target_group_arn }]
}

resource "aws_cloudwatch_dashboard" "golden_signals" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Traffic: Request count (visibility only)
      {
        type = "metric"
        x = 0
        y = 0
        width = 12
        height = 6
        properties = {
          title = "ALB - Request Count (per minute)"
          metrics = [ ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_name] ]
          period = 60
          stat = "Sum"
          view = "timeSeries"
          region = var.aws_region
          annotations = {}
        }
      },

      # Errors: 5xx count
      {
        type = "metric"
        x = 12
        y = 0
        width = 12
        height = 6
        properties = {
          title = "ALB - 5xx (Targets)"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "TargetGroup", var.target_group_arn],
            ["AWS/ApplicationELB", "RequestCount", "TargetGroup", var.target_group_arn]
          ]
          period = 60
          stat = "Sum"
          view = "timeSeries"
          region = var.aws_region
          annotations = {}
        }
      },

      # Latency: Target response time (P99)
      {
        type = "metric"
        x = 0
        y = 6
        width = 12
        height = 6
        properties = {
          title = "ALB - TargetResponseTime (P99)"
          metrics = [ ["AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", var.target_group_arn] ]
          period = 60
          stat = "p99"
          view = "timeSeries"
          region = var.aws_region
          annotations = {}
        }
      },

      # Saturation: ECS CPU & Memory
      {
        type = "metric"
        x = 12
        y = 6
        width = 12
        height = 6
        properties = {
          title = "ECS - CPU & Memory"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name]
          ]
          period = 60
          stat = "Average"
          view = "timeSeries"
          region = var.aws_region
          annotations = {}
        }
      },

      # RDS: CPU & Connections
      {
        type = "metric"
        x = 0
        y = 12
        width = 12
        height = 6
        properties = {
          title = "RDS - CPU & Connections"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_db_instance_identifier],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_db_instance_identifier]
          ]
          period = 60
          stat = "Average"
          view = "timeSeries"
          region = var.aws_region
          annotations = {}
        }
      },

      # ElastiCache: Cache Hit Rate
      {
        type = "metric"
        x = 12
        y = 12
        width = 12
        height = 6
        properties = {
          title = "ElastiCache - Cache Hit Rate"
          metrics = [ ["AWS/ElastiCache", "CacheHitRate", "ReplicationGroupId", var.redis_replication_group_id] ]
          period = 60
          stat = "Average"
          view = "timeSeries"
          region = var.aws_region
          annotations = {}
        }
      },

      # WAF blocked requests
      {
        type = "metric"
        x = 0
        y = 18
        width = 24
        height = 6
        properties = {
          title = "WAF - Blocked Requests"
          metrics = [ ["AWS/WAFV2", "BlockedRequests", "WebACL", var.waf_web_acl_arn] ]
          period = 60
          stat = "Sum"
          view = "timeSeries"
          region = var.aws_region
          annotations = {}
        }
      }
    ]
  })

  # Demo tag for interview pipeline: harmless metadata to trigger terraform plan
  tags = merge(var.common_tags, { InterviewDemo = "JPMC-2026-09-04" })
}

#########################
# CloudWatch Alarms (Four Golden Signals + others)
#########################

# Latency: P99 TargetResponseTime > 2s (over ~2 evaluation periods)
resource "aws_cloudwatch_metric_alarm" "latency_p99" {
  alarm_name          = "${var.project_name}-${var.environment}-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 2
  alarm_description   = "P99 latency above 2 seconds indicates degraded user experience"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  metric_query {
    id = "latency"
    metric {
      namespace = "AWS/ApplicationELB"
      metric_name = "TargetResponseTime"
      dimensions = { "TargetGroup" = var.target_group_arn }
      period = 60
      stat = "Maximum"
    }
    return_data = true
  }
}

# Errors: 5xx count - threshold > 10 errors in 5 minutes
resource "aws_cloudwatch_metric_alarm" "alb_5xx_count" {
  alarm_name          = "${var.project_name}-${var.environment}-error-rate-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  threshold           = 10
  alarm_description   = "Sustained 5xx errors indicate application or infrastructure failure"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  metric_query {
    id = "errors"
    metric {
      namespace = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      dimensions = { "TargetGroup" = var.target_group_arn }
      period = 60
      stat = "Sum"
    }
    return_data = true
  }
}

# Saturation: ECS CPU > 80% for 10 minutes (evaluation periods = 2 x 5min)
resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 80
  alarm_description   = "Auto scaling target is 70% — 80% indicates scaling is not keeping up"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  metric_query {
    id = "ecs_cpu"
    metric {
      namespace = "AWS/ECS"
      metric_name = "CPUUtilization"
      dimensions = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
      }
      period = 300
      stat = "Average"
    }
    return_data = true
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  alarm_name          = "${var.project_name}-${var.environment}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 80
  alarm_description   = "Memory saturation above 80% for 10 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  metric_query {
    id = "ecs_mem"
    metric {
      namespace = "AWS/ECS"
      metric_name = "MemoryUtilization"
      dimensions = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
      }
      period = 300
      stat = "Average"
    }
    return_data = true
  }
}

# RDS CPU > 70% (2 evaluation periods)
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 70
  alarm_description   = "RDS CPU > 70%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  metric_query {
    id = "rds_cpu"
    metric {
      namespace = "AWS/RDS"
      metric_name = "CPUUtilization"
      dimensions = { "DBInstanceIdentifier" = var.rds_db_instance_identifier }
      period = 60
      stat = "Average"
    }
    return_data = true
  }
}

# ALB healthy host count < 1 (fire immediately)
resource "aws_cloudwatch_metric_alarm" "alb_healthy_hosts" {
  alarm_name          = "${var.project_name}-${var.environment}-no-healthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  threshold           = 1
  alarm_description   = "ALB healthy host count < 1"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  metric_query {
    id = "healthy"
    metric {
      namespace = "AWS/ApplicationELB"
      metric_name = "HealthyHostCount"
      dimensions = { "TargetGroup" = var.target_group_arn }
      period = 60
      stat = "Minimum"
    }
    return_data = true
  }
}
