resource "aws_cloudwatch_event_rule" "EventRule" {
  name = "event-rule"
  description   = "Object create events on bucket s3://${var.s3_bucket_id}"
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
      "name": ["${var.s3_bucket_id}"]
    },
    "object": {
        "key" : [{"prefix" : "nuclear/"}]

    }
  }
}
EOF
}

resource "aws_cloudwatch_event_rule" "SolarTrigger" {
  schedule_expression = "rate(30 minutes)"
}