# https://www.terraform.io/docs/providers/aws/r/kms_key.html
# https://www.terraform.io/docs/providers/aws/d/kms_alias.html

##
# Rails application credentials
##
resource "aws_kms_key" "rails-credentials" {
  description         = "Encryption key for rails credentials in ${terraform.env}"
  is_enabled          = true
  enable_key_rotation = false

  policy = "${data.aws_iam_policy_document.rails-credentials.json}"

  tags = {
    Name    = "${var.application_name}-rails-credentials-${terraform.env}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

resource "aws_kms_alias" "rails-credentials" {
  name          = "alias/rails-credentials/${terraform.env}"
  target_key_id = "${aws_kms_key.rails-credentials.key_id}"
}

data "aws_iam_policy_document" "rails-credentials" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type = "AWS"

      # TODO: 業務用に書き換える
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/alpaca-tc-user",
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Enable ECS Permissions"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "${aws_iam_role.ecs_service_role.arn}",
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = ["*"]
  }
}

##
# RDS
##
resource "aws_kms_key" "rds-encryption" {
  description         = "RDS encryption key for data volume and master password in ${terraform.env}"
  is_enabled          = true
  enable_key_rotation = false

  policy = "${data.aws_iam_policy_document.rds-encryption.json}"

  tags = {
    Name    = "${var.application_name}-rds-encryption-${terraform.env}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

data "aws_iam_policy_document" "rds-encryption" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type = "AWS"

      # TODO: 業務用に書き換える
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/alpaca-tc-user",
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_alias" "rds-encryption" {
  name          = "alias/rds-encryption/${terraform.env}"
  target_key_id = "${aws_kms_key.rds-encryption.key_id}"
}
