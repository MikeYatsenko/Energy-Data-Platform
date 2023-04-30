# Display EC2 public IP
output "EC2-Public-IP" {
  value = aws_instance.EC2.public_ip
}

# Display the EventBridge rule
output "EventBridge-Rule-Name" {
  value       = aws_cloudwatch_event_rule.EventRule.name
  description = "The EventBridge Rule name"
}

# Display S3 Bucket Name
output "S3-Bucket-Name" {
  value       = aws_s3_bucket.S3Bucket.bucket
  description = "The S3 Bucket name"
}


# Display SQS Queue Name
output "SQS-Queue-Name" {
  value       = aws_sqs_queue.SQSQueue.name
  description = "The SNS Topic Name"
}

# Display RDS Database Name
output "RDS-Database-ARN" {
  value = aws_db_instance.RDSDatabase.arn
}

# Display Lambda Function Name
output "Lambda-Function-Name" {
  value = aws_lambda_function.LambdaFunction.function_name
}

# Display Cloudwatch Log Group
output "Cloudwatch_Log_Group" {
  value = aws_cloudwatch_log_group.CloudWatchLogGroup.name
}
