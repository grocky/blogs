resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Cloudfront origin access identity"
}

resource "aws_cloudfront_distribution" "blog_distribution" {
  origin {
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }

    domain_name = aws_s3_bucket.blog.bucket_regional_domain_name
    origin_id   = var.blog_domain_name
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Primary distribution for blog.rockygray.com"
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
    Name        = "blog.rockygray.com"
    Env         = "prod"
    Application = "blog.rockygray.com"
  }
}
