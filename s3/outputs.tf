output "bucket_id" {
  value = aws_s3_bucket.application_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.application_bucket.arn
}