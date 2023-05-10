data "archive_file" "LambdaZIPNuclear" {
  type = "zip"
  source_dir= "${path.module}/nuclear"
  output_path = "${path.module}/nuclear/nuclear.zip"
}

data "archive_file" "LambdaZIPSolar" {
  type = "zip"
  source_dir= "${path.module}/solar"
  output_path = "${path.module}/solar/solar.zip"
}

data "aws_caller_identity" "Current" {}

data "aws_region" "Current" {}