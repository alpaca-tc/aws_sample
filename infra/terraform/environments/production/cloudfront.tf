resource "aws_cloudfront_origin_access_identity" "public-assets" {
  comment = "${var.application_name}-public-assets-${terraform.env}"
}

resource "aws_cloudfront_distribution" "public-assets" {
  origin {
    domain_name = "${aws_s3_bucket.public-assets.bucket_domain_name}"
    origin_id   = "${var.application_name}-public-assets-${terraform.env}"

    # TODO: HTTPS化
    # custom_origin_config {
    #   origin_protocol_policy = "https-only"
    #   http_port = "80"
    #   https_port = "443"
    #   origin_ssl_protocols = ["TLSv1"]
    # }

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  # TODO: ログを有効にする

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["assets.${var.root_domain}"]
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.application_name}-public-assets-${terraform.env}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    # TODO: HTTPS化したら redirect-to-https にする
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  price_class = "PriceClass_200"
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  tags {
    Name        = "${var.application_name}-public-assets"
    AppName     = "${var.application_name}"
    Environment = "${terraform.env}"
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
