resource "aws_lb" "main" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  security_groups    = var.security_groups
  subnets            = var.subnets

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2              = var.enable_http2
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  idle_timeout = var.idle_timeout

  tags = var.tags
}

resource "aws_lb_target_group" "main" {
  for_each = var.target_groups

  name     = each.value.name
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = var.vpc_id

  health_check {
    enabled             = lookup(each.value.health_check, "enabled", true)
    healthy_threshold   = lookup(each.value.health_check, "healthy_threshold", 3)
    unhealthy_threshold = lookup(each.value.health_check, "unhealthy_threshold", 3)
    timeout             = lookup(each.value.health_check, "timeout", 5)
    interval            = lookup(each.value.health_check, "interval", 30)
    path                = lookup(each.value.health_check, "path", "/")
    matcher             = lookup(each.value.health_check, "matcher", "200")
    protocol            = lookup(each.value.health_check, "protocol", each.value.protocol)
  }

  tags = var.tags
}

resource "aws_lb_listener" "main" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.main.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = lookup(each.value, "ssl_policy", null)
  certificate_arn   = lookup(each.value, "certificate_arn", null)

  default_action {
    type             = each.value.default_action.type
    target_group_arn = lookup(each.value.default_action, "target_group_key", null) != null ? aws_lb_target_group.main[each.value.default_action.target_group_key].arn : null
  }
}

resource "aws_lb_target_group_attachment" "main" {
  for_each = var.target_group_attachments

  target_group_arn = aws_lb_target_group.main[each.value.target_group_key].arn
  target_id        = each.value.target_id
  port             = lookup(each.value, "port", null)
}
