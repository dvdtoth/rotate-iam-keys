/*
Deploy a lambda function that deletes IAM keys of specified groups, triggered periodically.
Set your groups, schedule and AWS profile
By @dvdtoth
*/

variable "groups" {
  type        = "string"
  default     = "Developers, Administrators"
  description = "Comma separated list of IAM groups"
}

variable "schedule" {
  type        = "string"
  default     = "cron(55 23 ? * 6 *)"
  description = "Schedule to trigger lambda, default 23:55 Friday. See doc: https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html"
}

provider "aws" {
  region  = "eu-west-2"
  profile = "YOURPROFILE"
}

resource "aws_iam_role" "revoke_keys_role" {
  name = "RevokeKeysRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "revoke_keys_role_policy" {
  name = "RevokeKeysRolePolicy"
  role = "${aws_iam_role.revoke_keys_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "iam:GetGroup",
        "iam:ListAccessKeys",
        "iam:DeleteAccessKey"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "revoke_keys" {
  filename         = "revoke_keys.zip"
  function_name    = "RevokeKeys"
  role             = "${aws_iam_role.revoke_keys_role.arn}"
  handler          = "handler.revoke"
  source_code_hash = "${base64sha256(file("revoke_keys.zip"))}"
  runtime          = "nodejs8.10"

  environment {
    variables = {
      GROUPS = "${var.groups}"
    }
  }
}

resource "aws_cloudwatch_event_rule" "weekly" {
  name                = "weekly"
  description         = "Fires every Friday at 23:55"
  schedule_expression = "${var.schedule}"
  is_enabled          = "true"
}

resource "aws_cloudwatch_event_target" "revoke_keys_weekly" {
  rule      = "${aws_cloudwatch_event_rule.weekly.name}"
  target_id = "revoke_keys"
  arn       = "${aws_lambda_function.revoke_keys.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_revoke_keys" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.revoke_keys.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.weekly.arn}"
}
