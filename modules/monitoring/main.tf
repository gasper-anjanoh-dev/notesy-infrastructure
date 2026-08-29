resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"

  # dashboard resource does not support tags in this provider version
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
      {
        type = "metric"
        x = 0
        y = 0
        width = 12
        height = 6
        properties = {
          title = "ALB - Request Count"
          metrics = [ ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_name]]
          period = 60
          stat = "Sum"
          view = "timeSeries"
          region = var.aws_region
          annotations = {}
        }
      },
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
      {
        type = "metric"
        x = 0
        y = 6
        width = 12
        height = 6
        properties = {
          title = "ALB - Target Response Time"
          metrics = [ ["AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", var.target_group_arn] ]
          period = 60
          stat = "Average"
          view = "timeSeries"
          region = var.aws_region
          annotations = {}
        }
      },
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

  
}

#########################
# CloudWatch Alarms
#########################

# 1) ALB 5xx rate > 1% for 5 minutes (metric math)
resource "aws_cloudwatch_metric_alarm" "alb_5xx_rate" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  threshold           = 1.0
  alarm_description   = "ALB 5xx rate greater than 1%"
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
    return_data = false
  }

  metric_query {
    id = "requests"
    metric {
      namespace = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      dimensions = { "TargetGroup" = var.target_group_arn }
      period = 60
      stat = "Sum"
    }
    return_data = false
  }

  metric_query {
    id = "error_rate"
    expression = "100 * errors / requests"
    label = "5xx percentage"
    return_data = true
  }
}

# 2) ECS CPU > 80% for 5 minutes
resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  threshold           = 80
  alarm_description   = "ECS service CPU > 80%"
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
      period = 60
      stat = "Average"
    }
    return_data = true
  }
}

# 3) ECS Memory > 80% for 5 minutes
resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  threshold           = 80
  alarm_description   = "ECS service Memory > 80%"
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
      period = 60
      stat = "Average"
    }
    return_data = true
  }
}

# 4) RDS CPU > 70% for 5 minutes
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
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

# 5) ALB healthy host count < 1
resource "aws_cloudwatch_metric_alarm" "alb_healthy_hosts" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-healthy-hosts"
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
