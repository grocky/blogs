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
    key    = "www.rockygray.com/terraform.tfstate"
  }
}

variable "blog_domain_name" {
  default = "blog.rockygray.com"
}

output "s3_website_url" {
  value = aws_s3_bucket.blog.website_endpoint
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.blog_distribution.domain_name
}

output "cloudfront_www_id" {
  value = aws_cloudfront_distribution.blog_distribution.id
}
