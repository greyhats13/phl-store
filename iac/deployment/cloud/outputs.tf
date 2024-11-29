# KMS Outputs
output "main_key_id" {
  value = module.kms_main.key_id
}

output "main_key_arn" {
  value = module.kms_main.key_arn
}