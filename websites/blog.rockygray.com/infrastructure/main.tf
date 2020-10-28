terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "grocky-tfstate"
    dynamodb_table = "tfstate-lock"
    region         = "us-east-1"
    key            = "blog.rockygray.com/terraform.tfstate"
  }
}

provider "aws" {
  region = "us-east-1"
}

data "terraform_remote_state" "rockygray_com" {
  backend = "s3"
  config = {
    bucket = "grocky-tfstate"
    region = "us-east-1"
    key    = "rockygray.com/terraform.tfstate"
  }
}

variable "blog_domain_name" {
  default = "blog.rockygray.com"
}

variable "preview_blog_domain_name" {
  default = "preview-blog.rockygray.com"
}

output "site_url" {
  value = {
    prod = aws_route53_record.blog.fqdn
    qa   = aws_route53_record.preview_blog.fqdn
  }
}

output "s3_website_url" {
  value = {
    prod = aws_s3_bucket.blog.website_endpoint
    qa   = aws_s3_bucket.preview_blog.website_endpoint
  }
}

output "cloudfront_url" {
  value = {
    prod = aws_cloudfront_distribution.blog_distribution.domain_name
    qa   = aws_cloudfront_distribution.preview_blog_distribution.domain_name
  }
}

output "cloudfront_www_id" {
  value = {
    prod = aws_cloudfront_distribution.blog_distribution.id
    qa   = aws_cloudfront_distribution.preview_blog_distribution.id
  }
}
