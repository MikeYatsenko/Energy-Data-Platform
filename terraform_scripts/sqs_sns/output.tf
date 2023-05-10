output "sqs_arn" {
  value = aws_sqs_queue.SQSQueue.arn
  description = "SQS queue arn"
}
