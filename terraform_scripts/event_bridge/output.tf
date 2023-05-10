output "EventBridge-Rule-ARN" {
  value       = aws_cloudwatch_event_rule.EventRule.arn
  description = "The EventBridge Rule arn"
}

output "EventBridge-Rule-Name" {
  value = aws_cloudwatch_event_rule.EventRule.name
  description = "The EventBridge Rule name for nuclear part"
}

output "EventBridge-Schedule-ARN" {
  value = aws_cloudwatch_event_rule.SolarTrigger.arn
  description = "The EventBridge Scheduled rule arn for solar part"
}

output "EventBridge-Schedule-Name" {
  value = aws_cloudwatch_event_rule.SolarTrigger.name
  description = "The EventBridge Scheduled rule arn for solar part"
}