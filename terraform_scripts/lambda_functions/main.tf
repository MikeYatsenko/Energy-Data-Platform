# Role to execute lambda nuclear
resource "aws_iam_role" "LambdaRoleNuclear" {
  name               = "LambdaRoleNuc"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_role" "LambdaRoleSolar" {
  name               = "LambdaRoleSolar"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# CloudWatch Log group to store Lambda logs
resource "aws_cloudwatch_log_group" "CloudWatchLogGroupNuclear" {
  name = "/aws/lambda/${aws_lambda_function.LambdaNuclear.function_name}"
  retention_in_days = 365
}


resource "aws_cloudwatch_log_group" "CloudWatchLogGroupSolar" {
  name = "/aws/lambda/${aws_lambda_function.LambdaSolar.function_name}"
  retention_in_days = 365
}


# Custom policy to read SQS queue and write to CloudWatch Logs with least privileges
resource "aws_iam_policy" "SQSLambdaNuclearPolicy" {
  name        = "SQSLambdaPolicy"
  path        = "/"
  description = "Policy for SQS to Lambda"
  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "${var.sqs_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:${data.aws_region.Current.name}:${data.aws_caller_identity.Current.account_id}:log-group:/aws/lambda/${aws_lambda_function.LambdaNuclear.function_name}:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "LambdaNuclearPolicyAttachment" {
  role = aws_iam_role.LambdaRoleNuclear.name
  policy_arn = aws_iam_policy.SQSLambdaNuclearPolicy.arn
}

resource "aws_lambda_function" "LambdaNuclear" {
  function_name = "lambda-nuclear"
  filename = data.archive_file.LambdaZIPNuclear.output_path
  source_code_hash = filebase64sha256(data.archive_file.LambdaZIPNuclear.output_path)
  role = aws_iam_role.LambdaRoleNuclear.arn
  handler = "nuclear.lambda_handler"
  runtime = "python3.9"
  environment {
    variables = {
      POWERTOOLS_SERVICE_NAME = "SQSLambda"
    }
  }
}

resource "aws_lambda_event_source_mapping" "SQSLambdaSourceMapping" {
  event_source_arn = var.sqs_arn
  function_name = aws_lambda_function.LambdaNuclear.function_name
}

resource "aws_lambda_function_event_invoke_config" "LambdaNuclearInvokeConfig" {
  function_name                = aws_lambda_function.LambdaNuclear.function_name
  maximum_event_age_in_seconds = 60
  maximum_retry_attempts       = 0
}

resource "aws_lambda_function_event_invoke_config" "LambdaSolarInvokeConfig" {
  function_name                = aws_lambda_function.LambdaSolar.function_name
  maximum_event_age_in_seconds = 60
  maximum_retry_attempts       = 0
}

resource "aws_lambda_function" "LambdaSolar" {
  function_name    = "lambda-solar"
  filename         = data.archive_file.LambdaZIPSolar.output_path
  source_code_hash = data.archive_file.LambdaZIPSolar.output_base64sha256
  handler          = "solar.lambda_handler"
  role             = aws_iam_role.LambdaRoleSolar.arn
  runtime          = "python3.9"

}

resource "aws_cloudwatch_event_target" "target_lambda_function" {
  rule = var.schedule_rule_name
  arn  = aws_lambda_function.LambdaSolar.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.LambdaSolar.function_name
  principal     = "events.amazonaws.com"
  source_arn    = var.schedule_rule_arn
}
