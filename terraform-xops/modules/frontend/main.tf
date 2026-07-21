terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

locals {
  cloudfront_cache_policy_caching_optimized_id                      = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  cloudfront_cache_policy_caching_disabled_id                       = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  cloudfront_origin_request_policy_all_viewer_except_host_header_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
}

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.name_prefix}-fe-${var.account_id}"
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cloudfront_origin_access_control" "frontend" {
  count                             = var.create_cloudfront_distribution ? 1 : 0
  name                              = "${var.name_prefix}-s3-oac"
  description                       = "OAC for ${var.name_prefix} private S3 frontend bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_wafv2_web_acl" "cloudfront" {
  count    = var.create_cloudfront_distribution && var.enable_cloudfront_waf ? 1 : 0
  provider = aws.us_east_1
  name     = "${var.name_prefix}-cloudfront-waf"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-common"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudfront_response_headers_policy" "security" {
  count = var.create_cloudfront_distribution ? 1 : 0
  name  = "${var.name_prefix}-security-headers"

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
  }
}

resource "aws_cloudfront_function" "spa_rewrite" {
  count   = var.create_cloudfront_distribution ? 1 : 0
  name    = "${var.name_prefix}-spa-rewrite"
  runtime = "cloudfront-js-1.0"
  comment = "Rewrite frontend SPA routes to index.html without touching API paths"
  publish = true
  code    = <<-EOT
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (request.method === 'GET' && !uri.includes('.') && !uri.startsWith('/api/') && !uri.startsWith('/socket.io/')) {
    request.uri = '/index.html';
  }

  return request;
}
EOT
}

resource "aws_cloudfront_distribution" "main" {
  count               = var.create_cloudfront_distribution ? 1 : 0
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.name_prefix} CloudFront distribution"
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class
  web_acl_id          = var.enable_cloudfront_waf ? aws_wafv2_web_acl.cloudfront[0].arn : null

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend[0].id

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  origin {
    domain_name = replace(var.api_endpoint, "https://", "")
    origin_id   = "http-api"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id           = "s3-frontend"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = local.cloudfront_cache_policy_caching_optimized_id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security[0].id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_rewrite[0].arn
    }
  }

  ordered_cache_behavior {
    path_pattern               = "/api/*"
    target_origin_id           = "http-api"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = local.cloudfront_cache_policy_caching_disabled_id
    origin_request_policy_id   = local.cloudfront_origin_request_policy_all_viewer_except_host_header_id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security[0].id
  }

  ordered_cache_behavior {
    path_pattern               = "/socket.io/*"
    target_origin_id           = "http-api"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = false
    cache_policy_id            = local.cloudfront_cache_policy_caching_disabled_id
    origin_request_policy_id   = local.cloudfront_origin_request_policy_all_viewer_except_host_header_id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security[0].id
  }

  ordered_cache_behavior {
    path_pattern               = "/rag"
    target_origin_id           = "http-api"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = local.cloudfront_cache_policy_caching_disabled_id
    origin_request_policy_id   = local.cloudfront_origin_request_policy_all_viewer_except_host_header_id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security[0].id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  lifecycle {
    # The AWS provider can report a no-op diff for CloudFront origin blocks
    # after updates that mix S3 OAC and custom origins.
    ignore_changes = [origin]
  }
}

resource "aws_s3_bucket_policy" "frontend_oac" {
  count  = var.create_cloudfront_distribution ? 1 : 0
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontServicePrincipalReadOnly"
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.frontend.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.main[0].arn
        }
      }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}
