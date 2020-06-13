data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid = "Allow CloudFront read access"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::${var.blog_domain_name}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
  statement {
    sid = "Allow CloudFront list access"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.blog_domain_name}"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket" "blog" {
  bucket = var.blog_domain_name
  acl    = "private"

  // @see This post: http://amzn.to/2Fa04ul explains why.
  policy = data.aws_iam_policy_document.bucket_policy.json
  website {
    index_document = "index.html"
    error_document = "index.html"
  }

  versioning {
    enabled = true
  }

  tags = {
    Name        = "blog.rockygray.com"
    Env         = "prod"
    Application = "blog.rockygray.com"
  }
}
