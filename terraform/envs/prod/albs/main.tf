module "loadbalancer" {
  source = "../../../modules/loadbalancer"

  name               = var.lb_name
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  security_groups    = var.security_groups
  subnets            = var.subnets
  vpc_id             = var.vpc_id

  enable_deletion_protection       = var.enable_deletion_protection
  enable_http2                     = var.enable_http2
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  idle_timeout                     = var.idle_timeout

  target_groups            = var.target_groups
  listeners                = var.listeners
  target_group_attachments = var.target_group_attachments

  tags = var.tags
}
