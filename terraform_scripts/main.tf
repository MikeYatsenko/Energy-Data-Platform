provider "aws" {
  access_key = 'pass your key'
  secret_key = 'pass you key'
  region = "us-west-1"

}


# Create a Security Group for an EC2 instance
resource "aws_security_group" "EC2SecurityGroup" {
  name = "EC2Security"
  description = "http/ssh connect"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "EC2Security"
  }
}


# Create EC2 instance
resource "aws_instance" "EC2" {
  ami			          = data.aws_ami.ubuntu.id
  instance_type           = "t2.micro"
  vpc_security_group_ids  = [aws_security_group.EC2SecurityGroup.id]

    tags = {
    Name = "ec2-instance"
  }

}

# Create S3 bucket
resource "aws_s3_bucket" "S3Bucket" {
  bucket = "nuc-s3-bucket"
}

resource "aws_s3_object" "S3BucketWindFolder" {
  bucket = "nuc-s3-bucket"
  key    = "wind/"
  source = "/dev/null"
}

resource "aws_s3_object" "S3BucketSolarFolder" {
  bucket = "nuc-s3-bucket"
  key    = "solar/"
  source = "/dev/null"
}

resource "aws_s3_object" "S3BucketNuclearFolder" {
  bucket = "nuc-s3-bucket"
  key    = "nuclear/"
  source = "/dev/null"
}

# Create S3 bucket EventBridge notification
resource "aws_s3_bucket_notification" "S3BucketNotification" {
  bucket      = aws_s3_bucket.S3Bucket.id
  eventbridge = true
}

# Create an EventBridge rule
resource "aws_cloudwatch_event_rule" "EventRule" {
  name = "event-rule"
  description   = "Object create events on bucket s3://${aws_s3_bucket.S3Bucket.id}"
  event_pattern = <<EOF
{
  "detail-type": [
    "Object Created"
  ],
  "source": [
    "aws.s3"
  ],
  "detail": {
    "bucket": {
      "name": ["${aws_s3_bucket.S3Bucket.id}"]
    }
  }
}
EOF
}

# Set the SNS topic as a target of the EventBridge rule
resource "aws_cloudwatch_event_target" "EventRuleTarget" {
  rule      = aws_cloudwatch_event_rule.EventRule.name
  arn       = aws_sns_topic.SNSTopic.arn
}

# Create a new SNS topic
resource "aws_sns_topic" "SNSTopic" {
  name = "sns-topic"
}

# Allow EventBridge to publish to the SNS topic
resource "aws_sns_topic_policy" "SNSTopicPolicy" {
  arn    = aws_sns_topic.SNSTopic.arn
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSEventsPermission",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.SNSTopic.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_cloudwatch_event_rule.EventRule.arn}"
        }
      }
    }
  ]
}
POLICY
}

# Create SQS queue
resource "aws_sqs_queue" "SQSQueue" {
  name = "sqs-queue"
}

# Allow SNS topic to publish to SQS queue
resource "aws_sqs_queue_policy" "SNSSQSPolicy" {
  queue_url = aws_sqs_queue.SQSQueue.id
  policy    = <<EOF
{
  "Version": "2012-10-17",
  "Id": "SNSSQSPolicy",
  "Statement": [
    {
      "Sid": "Allow SNS publish to SQS",
      "Effect": "Allow",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.SQSQueue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.SNSTopic.arn}"
        }
      }
    }
  ]
}
EOF
}

# Create SQS queue subscription to SNS
resource "aws_sns_topic_subscription" "SNSSQSTopicSubscription" {
  topic_arn = aws_sns_topic.SNSTopic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.SQSQueue.arn
}

# Create RDS Security Group
resource "aws_security_group" "RDSSecurity" {
  name        = "RDSSecurity"
  description = "Connection to RDS"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create RDS Database
resource "aws_db_instance" "RDSDatabase" {
  allocated_storage      = 10
  engine                 = "postgres"
  engine_version         = "13.7"
  username               = "username"
  password               = "password"
  publicly_accessible    = true
  skip_final_snapshot    = true
  instance_class         = "db.t3.micro"
  vpc_security_group_ids = [aws_security_group.RDSSecurity.id]
}

# Role to execute lambda
resource "aws_iam_role" "LambdaRole" {
  name               = "LambdaRole"
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
resource "aws_cloudwatch_log_group" "CloudWatchLogGroup" {
  name = "/aws/lambda/${aws_lambda_function.LambdaFunction.function_name}"
  retention_in_days = 365
}

# Custom policy to read SQS queue and write to CloudWatch Logs with least privileges
resource "aws_iam_policy" "SQSLambdaPolicy" {
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
      "Resource": "${aws_sqs_queue.SQSQueue.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:${data.aws_region.Current.name}:${data.aws_caller_identity.Current.account_id}:log-group:/aws/lambda/${aws_lambda_function.LambdaFunction.function_name}:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "LambdaPolicyAttachment" {
  role = aws_iam_role.LambdaRole.name
  policy_arn = aws_iam_policy.SQSLambdaPolicy.arn
}

resource "aws_lambda_function" "LambdaFunction" {
  function_name = "lambda-function"
  filename = data.archive_file.LambdaZIP.output_path
  source_code_hash = filebase64sha256(data.archive_file.LambdaZIP.output_path)
  role = aws_iam_role.LambdaRole.arn
  handler = "app.lambda_handler"
  timeout = 840
  runtime = "python3.9"
  layers = [
    "arn:aws:lambda:${data.aws_region.Current.name}:336392948345:layer:AWSSDKPandas-Python39:8"]
  environment {
    variables = {
      POWERTOOLS_SERVICE_NAME = "SQSLambda"
    }
  }
}

resource "aws_lambda_event_source_mapping" "SQSLambdaSourceMapping" {
  event_source_arn = aws_sqs_queue.SQSQueue.arn
  function_name = aws_lambda_function.LambdaFunction.function_name
}

resource "aws_lambda_function_event_invoke_config" "LambdaInvokeConfig" {
  function_name                = aws_lambda_function.LambdaFunction.function_name
  maximum_event_age_in_seconds = 60
  maximum_retry_attempts       = 0
}
