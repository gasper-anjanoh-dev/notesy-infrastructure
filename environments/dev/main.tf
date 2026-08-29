module "networking" {
  source       = "../../modules/networking"
  project_name = "notesy"
  environment  = "dev"
}

module "alb" {
  source            = "../../modules/alb"
  project_name      = "notesy"
  environment       = "dev"
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
}

module "waf" {
  source       = "../../modules/waf"
  project_name = "notesy"
  environment  = "dev"
  scope        = "CLOUDFRONT"
}

module "rds" {
  source             = "../../modules/rds"
  project_name       = "notesy"
  environment        = "dev"
  private_subnet_ids = module.networking.private_subnet_ids
  vpc_id             = module.networking.vpc_id
  db_name            = var.db_name
  db_username        = var.db_username
  db_instance_class  = var.db_instance_class
  allocated_storage  = var.allocated_storage
  backup_retention   = var.backup_retention
  kms_key_id         = var.kms_key_id
  multi_az           = true
  tags               = var.tags
  ecs_security_group_id = module.ecs.ecs_security_group_id
}

module "redis" {
  source             = "../../modules/redis"
  project_name       = "notesy"
  environment        = "dev"
  private_subnet_ids = module.networking.private_subnet_ids
  vpc_id             = module.networking.vpc_id
  node_type          = var.redis_node_type
  engine_version     = var.redis_engine_version
  auth_token         = var.redis_auth_token
  tags               = var.tags
  ecs_security_group_id = module.ecs.ecs_security_group_id
}

module "ecs" {
  source                = "../../modules/ecs"
  project_name          = "notesy"
  environment           = "dev"
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
  alb_listener_arn      = module.alb.alb_listener_arn
  app_image             = var.app_image
  db_secret_arn         = module.rds.db_secret_arn
  redis_secret_arn      = module.redis.redis_secret_arn
}

module "cdn" {
  source       = "../../modules/cdn"
  project_name = "notesy"
  environment  = "dev"
  alb_dns_name = module.alb.alb_dns_name
  waf_acl_arn  = module.waf.web_acl_arn
}

# Allow ECS tasks SG to access RDS SG
resource "aws_security_group_rule" "ecs_to_rds" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = module.rds.db_security_group_id
  source_security_group_id = module.ecs.ecs_security_group_id
}

resource "aws_security_group_rule" "ecs_to_redis" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = module.redis.redis_security_group_id
  source_security_group_id = module.ecs.ecs_security_group_id
}

module "autoscaling" {
  source       = "../../modules/autoscaling"
  project_name = "notesy"
  environment  = "dev"
  cluster_name = module.ecs.cluster_name
  service_name = module.ecs.service_name
  min_capacity = 1
  max_capacity = 10
}

module "monitoring" {
  source                    = "../../modules/monitoring"
  project_name              = "notesy"
  environment               = "dev"
  alb_name                  = module.alb.alb_arn
  target_group_arn          = module.alb.target_group_arn
  ecs_cluster_name          = module.ecs.cluster_name
  ecs_service_name          = module.ecs.service_name
  rds_db_instance_identifier = module.rds.db_endpoint
  redis_replication_group_id = module.redis.redis_endpoint
  waf_web_acl_arn           = module.waf.web_acl_arn
  alarm_email               = var.alarm_email
}
