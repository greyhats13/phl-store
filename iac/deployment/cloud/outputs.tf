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

# Route53 Outputs
output "route53_zone_arn" {
  value = module.zones_main.route53_zone_zone_arn
}

# RDS Aurora Outputs
output "aurora_cluster_endpoint" {
  value = module.aurora_main.cluster_endpoint
}

output "aurora_cluster_reader_endpoint" {
  value = module.aurora_main.cluster_reader_endpoint
}

output "aurora_cluster_port" {
  value = module.aurora_main.cluster_port
}

output "aurora_cluster_username" {
  value = module.aurora_main.cluster_master_username
}

# # EKS Outputs
output "eks_cluster_name" {
  value = module.eks_main.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks_main.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  value = module.eks_main.cluster_certificate_authority_data
}

# EKS Karpenter

# Cognito Outputs
output "cognito_user_pool_id" {
  value = module.cognito_pool.cognito_user_pool_id
}

output "cognito_user_pool_arn" {
  value = module.cognito_pool.cognito_user_pool_arn
}

output "cognito_user_pool_client_id" {
  value = module.cognito_pool.cognito_user_pool_client_id
}

output "cognito_user_pool_client_secret" {
  value     = module.cognito_pool.cognito_user_pool_client_secret
  sensitive = true
}

output "cognito_user_pool_endpoint" {
  value = module.cognito_pool.cognito_user_pool_endpoint
}

# API Gateway Outputs
output "api_id" {
  value = module.api.api_id
}

output "api_endpoint" {
  value = module.api.api_endpoint
}
