output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.this.id
}

output "cognito_user_pool_arn" {
  value = aws_cognito_user_pool.this.arn
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.this.id
}

output "cognito_user_pool_client_secret" {
  value = aws_cognito_user_pool_client.this.client_secret
}

output "cognito_user_pool_domain" {
  value = aws_cognito_user_pool_domain.main.domain
}

# output "cognito_issuer_url" {
#   value = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.this.id}"
# }

output "cognito_user_pool_endpoint" {
  value = aws_cognito_user_pool.this.endpoint
}

output "cognito_authrization_scopes" {
  value = aws_cognito_resource_server.resource_servers["apigw"].scope_identifiers
}
