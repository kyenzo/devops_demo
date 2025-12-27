output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = module.loadbalancer.load_balancer_id
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = module.loadbalancer.load_balancer_arn
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.loadbalancer.load_balancer_dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.loadbalancer.load_balancer_zone_id
}

output "target_group_arns" {
  description = "ARNs of the target groups"
  value       = module.loadbalancer.target_group_arns
}

output "listener_arns" {
  description = "ARNs of the listeners"
  value       = module.loadbalancer.listener_arns
}
