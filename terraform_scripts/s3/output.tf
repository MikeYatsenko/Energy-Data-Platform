# Display S3 Bucket Name
output "bucket_id" {
  value       = aws_s3_bucket.S3Bucket.id
  description = "The S3 Bucket ID"
}
