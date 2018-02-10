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
}
