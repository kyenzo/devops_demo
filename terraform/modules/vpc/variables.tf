variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = []
}

variable "create_internet_gateway" {
  description = "Whether to create an internet gateway"
  type        = bool
  default     = true
}

variable "create_nat_gateway" {
  description = "Whether to create NAT gateways"
  type        = bool
  default     = true
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways to create (for cost savings, use 1 instead of one per AZ)"
  type        = number
  default     = 1
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# VPC Peering - Requester side
variable "create_peering_connection" {
  description = "Create a VPC peering connection (requester side)"
  type        = bool
  default     = false
}

variable "peer_vpc_id" {
  description = "ID of the peer VPC (required when create_peering_connection = true)"
  type        = string
  default     = null
}

variable "peer_region" {
  description = "Region of the peer VPC (for cross-region peering)"
  type        = string
  default     = null
}

# VPC Peering - Accepter side
variable "accept_peering_connection" {
  description = "Accept an incoming VPC peering connection (accepter side)"
  type        = bool
  default     = false
}

variable "peering_connection_id" {
  description = "ID of the peering connection to accept (required when accept_peering_connection = true)"
  type        = string
  default     = null
}

# Shared peering routing
variable "peer_vpc_cidr" {
  description = "CIDR block of the peer VPC - used to add routes in route tables"
  type        = string
  default     = null
}
