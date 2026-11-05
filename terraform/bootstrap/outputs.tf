output "bucket_name" {
  description = "Name of the state bucket."
  value       = cloudflare_r2_bucket.tfstate.name
}

output "s3_endpoint" {
  description = "S3-compatible endpoint to use in other stacks' backend blocks."
  value       = "https://${var.account_id}.r2.cloudflarestorage.com"
}
