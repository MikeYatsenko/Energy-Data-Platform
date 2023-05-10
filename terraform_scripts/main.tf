provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_access_secret_key
  region = "us-west-1"

}

module "module_ec2"{
  source = ".//ec2"
}

module "module_s3" {
  source = ".//s3"
}

module "module_event_bridge" {
  source = ".//event_bridge"
  s3_bucket_id = module.module_s3.bucket_id
}

module "module_sqs_sns"{
  source = ".//sqs_sns"
  rule_sns_arn = module.module_event_bridge.EventBridge-Rule-ARN
  rule_sns_name = module.module_event_bridge.EventBridge-Rule-Name
}

module "module_rds"{
  source = ".//rds_postgres"
}

module "module_lambda" {
  sqs_arn = module.module_sqs_sns.sqs_arn
  schedule_rule_arn = module.module_event_bridge.EventBridge-Schedule-ARN
  schedule_rule_name = module.module_event_bridge.EventBridge-Schedule-Name
  source = ".//lambda_functions"
}