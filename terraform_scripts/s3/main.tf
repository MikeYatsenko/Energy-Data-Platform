# Create S3 bucket
resource "aws_s3_bucket" "S3Bucket" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_object" "S3BucketWindFolder" {
  bucket = var.s3_bucket_name
  key    = "wind/"
  source = "/dev/null"
}

resource "aws_s3_object" "S3BucketSolarFolder" {
  bucket = var.s3_bucket_name
  key    = "solar/"
  source = "/dev/null"
}

resource "aws_s3_object" "S3BucketNuclearFolder" {
  bucket = var.s3_bucket_name
  key    = "nuclear/"
  source = "/dev/null"
}

# Create S3 bucket EventBridge notification
resource "aws_s3_bucket_notification" "S3BucketNotification" {
  bucket      = aws_s3_bucket.S3Bucket.id
  eventbridge = true
}