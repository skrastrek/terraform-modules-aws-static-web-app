locals {
  auth_origin_id      = "auth"
  s3_bucket_origin_id = "${var.name_prefix}-s3-bucket"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  id = "216adef6-5c7f-47e4-b989-5492eafa07d3"
}

data "aws_cloudfront_response_headers_policy" "security_headers" {
  id = "67f7725c-6f97-4210-82d7-5512b31e9d03"
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.name_prefix}-s3-bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  comment = var.name_prefix

  enabled             = true
  wait_for_deployment = true

  is_ipv6_enabled = true
  http_version    = "http2and3"
  price_class     = "PriceClass_100"

  default_root_object = var.default_root_object

  aliases = [var.domain_name]

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn_us_east_1
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  origin {
    origin_id                = local.s3_bucket_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
  }

  dynamic "origin" {
    for_each = length(var.auth_ordered_cache_behaviours) > 0 ? [local.auth_origin_id] : []
    content {
      origin_id   = local.auth_origin_id
      domain_name = "will-never-be-reached.org"

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_ssl_protocols   = ["TLSv1.2"]
        origin_protocol_policy = "match-viewer"
      }
    }
  }

  dynamic "origin" {
    for_each = var.custom_origins
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id

      connection_attempts = origin.value.connection_attempts
      connection_timeout  = origin.value.connection_timeout

      custom_origin_config {
        http_port                = origin.value.custom_origin_config.http_port
        https_port               = origin.value.custom_origin_config.https_port
        origin_protocol_policy   = origin.value.custom_origin_config.origin_protocol_policy
        origin_ssl_protocols     = origin.value.custom_origin_config.origin_ssl_protocols
        origin_keepalive_timeout = origin.value.custom_origin_config.origin_keepalive_timeout
        origin_read_timeout      = origin.value.custom_origin_config.origin_read_timeout
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.auth_ordered_cache_behaviours
    content {
      path_pattern     = ordered_cache_behavior.value.path_pattern
      target_origin_id = local.auth_origin_id

      allowed_methods = ["GET", "HEAD"]
      cached_methods  = ["GET", "HEAD"]

      compress = true

      viewer_protocol_policy = "redirect-to-https"

      cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
      origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all_viewer.id
      response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security_headers.id

      lambda_function_association {
        event_type   = ordered_cache_behavior.value.event_type
        lambda_arn   = ordered_cache_behavior.value.lambda_arn
        include_body = ordered_cache_behavior.value.include_body
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.s3_bucket_ordered_cache_behaviours
    content {
      path_pattern     = ordered_cache_behavior.value.path_pattern
      target_origin_id = local.s3_bucket_origin_id

      allowed_methods = ordered_cache_behavior.value.allowed_methods
      cached_methods  = ordered_cache_behavior.value.cached_methods

      compress = ordered_cache_behavior.value.compress

      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy

      cache_policy_id = ordered_cache_behavior.value.cache_policy_id

      dynamic "function_association" {
        for_each = ordered_cache_behavior.value.function_associations

        content {
          event_type   = function_association.value.event_type
          function_arn = function_association.value.function_arn
        }
      }

      dynamic "lambda_function_association" {
        for_each = ordered_cache_behavior.value.lambda_function_associations
        content {
          event_type   = lambda_function_association.value.event_type
          lambda_arn   = lambda_function_association.value.lambda_arn
          include_body = lambda_function_association.value.include_body
        }
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.custom_ordered_cache_behaviours
    content {
      path_pattern     = ordered_cache_behavior.value.path_pattern
      target_origin_id = ordered_cache_behavior.value.target_origin_id

      allowed_methods = ordered_cache_behavior.value.allowed_methods
      cached_methods  = ordered_cache_behavior.value.cached_methods

      compress = ordered_cache_behavior.value.compress

      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy

      cache_policy_id            = ordered_cache_behavior.value.cache_policy_id
      origin_request_policy_id   = ordered_cache_behavior.value.origin_request_policy_id
      response_headers_policy_id = ordered_cache_behavior.value.response_headers_policy_id

      dynamic "function_association" {
        for_each = ordered_cache_behavior.value.function_associations

        content {
          event_type   = function_association.value.event_type
          function_arn = function_association.value.function_arn
        }
      }

      dynamic "lambda_function_association" {
        for_each = var.auth_default_cache_behaviour != null ? [var.auth_default_cache_behaviour] : []
        content {
          event_type   = lambda_function_association.value.event_type
          lambda_arn   = lambda_function_association.value.lambda_arn
          include_body = lambda_function_association.value.include_body
        }
      }


      dynamic "lambda_function_association" {
        for_each = ordered_cache_behavior.value.lambda_function_associations
        content {
          event_type   = lambda_function_association.value.event_type
          lambda_arn   = lambda_function_association.value.lambda_arn
          include_body = lambda_function_association.value.include_body
        }
      }
    }
  }

  default_cache_behavior {
    target_origin_id = local.s3_bucket_origin_id

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    compress = true

    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id

    dynamic "lambda_function_association" {
      for_each = var.auth_default_cache_behaviour != null ? [var.auth_default_cache_behaviour] : []
      content {
        event_type   = lambda_function_association.value.event_type
        lambda_arn   = lambda_function_association.value.lambda_arn
        include_body = lambda_function_association.value.include_body
      }
    }
  }

  dynamic "custom_error_response" {
    for_each = var.spa_enabled ? var.spa_custom_error_response_codes : []
    content {
      error_code         = custom_error_response.value
      response_code      = 200
      response_page_path = "/${var.default_root_object}"
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  web_acl_id = var.web_acl_arn

  tags = var.tags
}
