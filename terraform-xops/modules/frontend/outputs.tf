output "frontend_bucket" {
  value = aws_s3_bucket.frontend.id
}

output "cloudfront_domain_name" {
  value = try(aws_cloudfront_distribution.main[0].domain_name, null)
}

output "cloudfront_distribution_id" {
  value = try(aws_cloudfront_distribution.main[0].id, null)
}

output "waf_web_acl_arn" {
  value = try(aws_wafv2_web_acl.cloudfront[0].arn, null)
}
