output "mimir_bucket_name" {
  description = "S3 bucket name for Mimir metrics storage"
  value       = aws_s3_bucket.mimir.bucket
}

output "loki_bucket_name" {
  description = "S3 bucket name for Loki log storage"
  value       = aws_s3_bucket.loki.bucket
}

output "mimir_role_arn" {
  description = "IAM role ARN for Mimir Pod Identity"
  value       = module.mimir_pod_identity.iam_role_arn
}

output "loki_role_arn" {
  description = "IAM role ARN for Loki Pod Identity"
  value       = module.loki_pod_identity.iam_role_arn
}
