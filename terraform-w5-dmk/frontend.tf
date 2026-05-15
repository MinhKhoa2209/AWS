resource "aws_s3_bucket" "frontend" {
  bucket = "${local.name_prefix}-fe-${data.aws_caller_identity.current.account_id}"
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

resource "aws_cloudfront_origin_access_control" "frontend" {
  count                             = var.create_cloudfront_distribution ? 1 : 0
  name                              = "${local.name_prefix}-s3-oac"
  description                       = "OAC for ${local.name_prefix} private S3 frontend bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_vpc_origin" "backend" {
  count = var.create_cloudfront_distribution ? 1 : 0

  vpc_origin_endpoint_config {
    arn                    = aws_lb.backend.arn
    name                   = "${local.name_prefix}-alb-vpc-origin"
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "http-only"

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }

  tags = {
    Name = "${local.name_prefix}-alb-vpc-origin"
  }
}

resource "aws_wafv2_web_acl" "cloudfront" {
  count    = var.create_cloudfront_distribution ? 1 : 0
  provider = aws.us_east_1
  name     = "${local.name_prefix}-cloudfront-waf"
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
      metric_name                = "${local.name_prefix}-common"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudfront_response_headers_policy" "security" {
  count = var.create_cloudfront_distribution ? 1 : 0
  name  = "${local.name_prefix}-security-headers"

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

resource "aws_cloudfront_distribution" "main" {
  count           = var.create_cloudfront_distribution ? 1 : 0
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${local.name_prefix} CloudFront distribution"
  web_acl_id      = aws_wafv2_web_acl.cloudfront[0].arn

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend[0].id

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  origin {
    domain_name = aws_lb.backend.dns_name
    origin_id   = "alb-vpc-origin"

    vpc_origin_config {
      vpc_origin_id = aws_cloudfront_vpc_origin.backend[0].id
    }
  }

  default_cache_behavior {
    target_origin_id           = "s3-frontend"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security[0].id
  }

  ordered_cache_behavior {
    path_pattern               = "/api/*"
    target_origin_id           = "alb-vpc-origin"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security[0].id
  }

  ordered_cache_behavior {
    path_pattern               = "/socket.io/*"
    target_origin_id           = "alb-vpc-origin"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = false
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security[0].id
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
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
    # The AWS provider currently reports a no-op diff for CloudFront origin blocks
    # after apply when VPC Origin and OAC are both configured.
    ignore_changes = [origin]
  }

  depends_on = [aws_cloudfront_vpc_origin.backend]
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
