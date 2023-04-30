data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_caller_identity" "Current" {}

data "aws_region" "Current" {}

data "archive_file" "LambdaZIP" {
  type = "zip"
  source_dir= "${path.module}/app"
  output_path = "${path.module}/app/app.zip"
}
