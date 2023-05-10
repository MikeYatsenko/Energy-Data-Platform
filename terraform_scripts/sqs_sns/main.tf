resource "aws_sns_topic" "SNSTopic" {
  name = "sns-topic"
}


resource "aws_cloudwatch_event_target" "EventRuleTarget" {
  rule      = var.rule_sns_name
  arn       = aws_sns_topic.SNSTopic.arn
}

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
          "aws:SourceArn": "${var.rule_sns_arn}"
        }
      }
    }
  ]
}
POLICY
}

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