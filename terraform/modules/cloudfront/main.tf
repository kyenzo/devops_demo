resource "aws_cloudfront_distribution" "this" {
  enabled = true
  comment = "Failover CDN: prod (primary) → distant (secondary)"

  # Prod NLB origin (primary)
  origin {
    origin_id   = "prod"
    domain_name = var.prod_origin_domain

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Distant NLB origin (failover)
  origin {
    origin_id   = "distant"
    domain_name = var.distant_origin_domain

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Origin group: prod is primary, distant is failover on 5xx
  origin_group {
    origin_id = "failover-group"

    failover_criteria {
      status_codes = [500, 502, 503, 504]
    }

    member {
      origin_id = "prod"
    }

    member {
      origin_id = "distant"
    }
  }

  # Route all traffic through the failover group
  # TTL=0 so CloudFront doesn't cache — responses always come live from the origin
  default_cache_behavior {
    target_origin_id       = "failover-group"
    viewer_protocol_policy = "allow-all"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use the default *.cloudfront.net certificate (no custom domain needed)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}
