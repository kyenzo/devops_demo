variable "name" {
  description = "Name of the load balancer"
  type        = string
}

variable "internal" {
  description = "Whether the load balancer is internal or external"
  type        = bool
  default     = false
}

variable "load_balancer_type" {
  description = "Type of load balancer (application, network, gateway)"
  type        = string
  default     = "application"
}

variable "security_groups" {
  description = "List of security group IDs to assign to the load balancer"
  type        = list(string)
}

variable "subnets" {
  description = "List of subnet IDs to attach to the load balancer"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the load balancer will be created"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the load balancer"
  type        = bool
  default     = false
}

variable "enable_http2" {
  description = "Enable HTTP/2 on the load balancer"
  type        = bool
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "Time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "target_groups" {
  description = "Map of target groups to create"
  type        = any
  default     = {}
}

variable "listeners" {
  description = "Map of listeners to create"
  type        = any
  default     = {}
}

variable "target_group_attachments" {
  description = "Map of target group attachments"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
