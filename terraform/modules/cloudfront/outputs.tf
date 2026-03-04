output "distribution_domain_name" {
  description = "The CloudFront distribution domain name (e.g. d1234abcd.cloudfront.net)"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_id" {
  description = "The CloudFront distribution ID"
  value       = aws_cloudfront_distribution.this.id
}
