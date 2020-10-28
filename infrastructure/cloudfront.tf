resource "aws_cloudfront_distribution" "blog_distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = aws_s3_bucket.blog.website_endpoint
    origin_id   = var.blog_domain_name
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Primary distribution for ${var.blog_domain_name}"
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = var.blog_domain_name

    compress    = true
    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  aliases = [var.blog_domain_name]

  ordered_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    path_pattern           = "/index.html"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = var.blog_domain_name

    compress    = true
    min_ttl     = 0
    default_ttl = 5
    max_ttl     = 5

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = data.terraform_remote_state.rockygray_com.outputs.certificate_arn
    ssl_support_method  = "sni-only"
  }

  tags = {
    Name        = var.blog_domain_name
    Env         = "prod"
    Application = var.blog_domain_name
  }
}

resource "aws_cloudfront_distribution" "preview_blog_distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = aws_s3_bucket.preview_blog.website_endpoint
    origin_id   = var.preview_blog_domain_name
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Preview distribution for ${var.blog_domain_name}"
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = var.preview_blog_domain_name

    compress    = true
    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  aliases = [var.preview_blog_domain_name]

  ordered_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    path_pattern           = "/index.html"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = var.preview_blog_domain_name

    compress    = true
    min_ttl     = 0
    default_ttl = 5
    max_ttl     = 5

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = data.terraform_remote_state.rockygray_com.outputs.certificate_arn
    ssl_support_method  = "sni-only"
  }

  tags = {
    Name        = var.preview_blog_domain_name
    Env         = "qa"
    Application = var.blog_domain_name
  }
}
