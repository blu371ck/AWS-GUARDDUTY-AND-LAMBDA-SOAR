resource "aws_sns_topic" "forensics_notifications" {
  name = "ForensicsTeamTopic-Standard"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.forensics_notifications.arn
  protocol  = "email"
  endpoint  = var.subscriber_email
}

resource "aws_ssm_parameter" "sns_topic_arn" {
  name  = "/cloud-warden/forensics_topic_arn"
  type  = "String"
  value = aws_sns_topic.forensics_notifications.arn
}

resource "aws_ssm_parameter" "quarantine_sg_id" {
  name  = "/cloud-warden/quarantine_sg_id"
  type  = "String"
  value = var.quarantine_sg_id
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "GuardDuty-SOAR-Responder-Role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "guardduty_read_only" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonGuardDutyReadOnlyAccess"
}

resource "aws_iam_role_policy" "soar_permissions" {
  name = "SOAR-Remediation-Permissions"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ec2:ModifyInstanceAttribute",
          "ec2:CreateSnapshot",
          "ec2:TerminateInstances",
          "ec2:DescribeInstances",
          "ec2:CreateTags",
          "ec2:DescribeTags"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "ssm:GetParameter",
        Resource = [
          aws_ssm_parameter.quarantine_sg_id.arn,
          aws_ssm_parameter.sns_topic_arn.arn
        ]
      },
      {
        Effect = "Allow",
        Action = "sns:Publish",
        Resource = aws_sns_topic.forensics_notifications.arn
      }
    ]
  })
}

resource "aws_lambda_layer_version" "aws_reflex_layer" {
  filename            = var.layer_zip_path
  layer_name          = "aws-reflex"
  compatible_runtimes = ["python3.11"]
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.lambda_function_dir
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "guardduty_responder" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "GuardDuty-SOAR-Responder"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.11"
  timeout          = 60
  layers           = [aws_lambda_layer_version.aws_reflex_layer.arn]
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

resource "aws_cloudwatch_event_rule" "guardduty_finding_rule" {
  name        = "GuardDuty-Finding-Trigger"
  description = "Triggers the SOAR Lambda function on a new GuardDuty finding."

  event_pattern = jsonencode({
    source      = ["aws.guardduty"],
    detail-type = ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_finding_rule.name
  target_id = "GuardDuty-SOAR-Responder-Target"
  arn       = aws_lambda_function.guardduty_responder.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.guardduty_responder.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_finding_rule.arn
}
