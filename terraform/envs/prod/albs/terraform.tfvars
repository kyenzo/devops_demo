lb_name            = "prod-alb"
internal           = false
load_balancer_type = "application"

# These need to be populated with actual values from your AWS account
security_groups = []  # Add your security group IDs here
subnets         = []  # Add your subnet IDs here
vpc_id          = ""  # Add your VPC ID here (default VPC ID)

enable_deletion_protection       = false
enable_http2                     = true
enable_cross_zone_load_balancing = true
idle_timeout                     = 60

# No target groups, listeners, or attachments - basic load balancer only
target_groups            = {}
listeners                = {}
target_group_attachments = {}

tags = {
  Environment = "prod"
  ManagedBy   = "terraform"
}
