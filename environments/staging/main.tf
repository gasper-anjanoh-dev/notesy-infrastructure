module "networking" {
  source       = "../../modules/networking"
  project_name = "notesy"
  environment  = "staging"
}

module "alb" {
  source            = "../../modules/alb"
  project_name      = "notesy"
  environment       = "staging"
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
}

module "waf" {
  source       = "../../modules/waf"
  project_name = "notesy"
  environment  = "staging"
  scope        = "REGIONAL"
}

module "ecs" {
  source                = "../../modules/ecs"
  project_name          = "notesy"
  environment           = "staging"
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
  app_image             = var.app_image
}

module "cdn" {
  source       = "../../modules/cdn"
  project_name = "notesy"
  environment  = "staging"
  alb_dns_name = module.alb.alb_dns_name
  waf_acl_arn  = module.waf.web_acl_arn
}
