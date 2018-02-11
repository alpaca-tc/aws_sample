resource "aws_route53_zone" "terraform-example-net" {
  name = "terraform-example.net."
}

resource "aws_route53_record" "terraform-example-net-ns" {
  zone_id = "${aws_route53_zone.terraform-example-net.zone_id}"
  name    = "terraform-example.net."
  type    = "NS"
  ttl     = "60"

  records = [
    "ns-695.awsdns-22.net.",
    "ns-1526.awsdns-62.org.",
    "ns-1829.awsdns-36.co.uk.",
    "ns-193.awsdns-24.com.",
  ]
}

resource "aws_route53_record" "terraform-example-net" {
  zone_id = "${aws_route53_zone.terraform-example-net.zone_id}"
  name    = "terraform-example.net."
  type    = "A"

  alias {
    name                   = "${aws_alb.main.dns_name}"
    zone_id                = "${aws_alb.main.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "terraform-example-net-cname" {
  zone_id = "${aws_route53_zone.terraform-example-net.zone_id}"
  name    = "www.terraform-example.net."
  type    = "CNAME"

  alias {
    name                   = "${aws_alb.main.dns_name}"
    zone_id                = "${aws_alb.main.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "terraform-example-net-assets" {
  zone_id = "${aws_route53_zone.terraform-example-net.zone_id}"
  name    = "assets.terraform-example.net."
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.public-assets.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.public-assets.hosted_zone_id}"
    evaluate_target_health = false
  }
}
