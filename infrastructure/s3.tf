resource "aws_s3_bucket" "blog" {
  bucket = var.blog_domain_name
  acl    = "public-read"

  // @see This post: http://amzn.to/2Fa04ul explains why.
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddPerm",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${var.blog_domain_name}/*"]
    }
  ]
}
POLICY

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
