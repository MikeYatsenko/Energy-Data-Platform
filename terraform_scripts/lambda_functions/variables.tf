variable "sqs_arn" {
  type = string
  description = "Queue arn for pass to lambda nuclear"
}

variable "schedule_rule_arn" {
  type = string
  description = "Scheduled rule arn for pass to lambda solar function"
}

variable "schedule_rule_name" {
  type = string
  description = "Scheduled rule name for pass to lambda solar function"
}