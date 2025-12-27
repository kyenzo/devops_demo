module "albs" {
  source = "./albs"

  lb_name         = var.lb_name
  security_groups = var.security_groups
  subnets         = var.subnets
  vpc_id          = var.vpc_id
}
