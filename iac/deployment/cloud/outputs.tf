# KMS Outputs
output "main_key_id" {
  value = module.kms_main.key_id
}

output "main_key_arn" {
  value = module.kms_main.key_arn
}

# S3 Outputs
output "tfstate_bucket_id" {
  value = module.bucket_tfstate.s3_bucket_id
}

output "tfstate_bucket_arn" {
  value = module.bucket_tfstate.s3_bucket_arn
}

# VPC Outputs
