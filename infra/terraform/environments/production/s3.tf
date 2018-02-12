##
# albのログを保存する
##
resource "aws_s3_bucket" "alb-access-logs" {
  bucket = "${var.application_name}-alb-access-logs-${terraform.env}"
  acl    = "private"

  tags {
    Name    = "${var.application_name}-alb-access-logs"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

resource "aws_s3_bucket_policy" "alb-access-logs" {
  bucket = "${aws_s3_bucket.alb-access-logs.id}"
  policy = "${data.aws_iam_policy_document.alb-access-logs.json}"
}

data "aws_iam_policy_document" "alb-access-logs" {
  statement {
    sid    = "AllowAlbToPushLogs"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        # 東京リージョンのALBは固定値
        # ref: https://docs.aws.amazon.com/ja_jp/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions
        "arn:aws:iam::582318560864:root",
      ]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.alb-access-logs.arn}/main-${terraform.env}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]
  }
}

##
# Railsのassetsを配信する
##
resource "aws_s3_bucket" "public-assets" {
  bucket = "${var.application_name}-public-assets"
  acl    = "private"

  tags {
    Name    = "${var.application_name}-public-assets"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

resource "aws_s3_bucket_policy" "public-assets" {
  bucket = "${aws_s3_bucket.public-assets.id}"
  policy = "${data.aws_iam_policy_document.public-assets.json}"
}

data "aws_iam_policy_document" "public-assets" {
  statement {
    sid    = "AllowUserToPushAssets"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/alpaca-tc-user",
      ]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      "${aws_s3_bucket.public-assets.arn}/*",
    ]
  }

  statement {
    sid    = "AllowCloudFrontToGetObject"
    effect = "Allow"

    principals = {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.public-assets.iam_arn}"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.public-assets.arn}/*",
    ]
  }
}
