resource "aws_route53_record" "blog" {
  zone_id = data.terraform_remote_state.rockygray_com.outputs.root_zone_id
  name    = "blog.rockygray.com"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.blog_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.blog_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}