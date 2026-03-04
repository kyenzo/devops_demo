variable "prod_origin_domain" {
  description = "DNS name of the prod NLB (ingress-nginx)"
  type        = string
}

variable "distant_origin_domain" {
  description = "DNS name of the distant NLB (ingress-nginx)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the CloudFront distribution"
  type        = map(string)
  default     = {}
}
