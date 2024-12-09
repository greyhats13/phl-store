resource "aws_cognito_user_pool" "this" {
  name                     = var.name
  username_attributes      = var.username_attributes
  auto_verified_attributes = var.auto_verified_attributes
  password_policy {
    minimum_length    = var.password_policy.minimum_length
    require_lowercase = var.password_policy.require_lowercase
    require_uppercase = var.password_policy.require_uppercase
    require_numbers   = var.password_policy.require_numbers
    require_symbols   = var.password_policy.require_symbols
  }
  tags = var.tags
}

resource "aws_cognito_user_pool_domain" "main" {
  domain          = var.domain
  certificate_arn = var.certificate_arn
  user_pool_id    = aws_cognito_user_pool.this.id
}

resource "aws_route53_record" "parent" {
  zone_id = var.zone_id
  name    = "phl.blast.co.id"
  type    = "A"

  alias {
    name                   = var.alb_dns
    zone_id                = var.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "child" {
  name    = aws_cognito_user_pool_domain.main.domain
  type    = "A"
  zone_id = var.zone_id
  alias {
    evaluate_target_health = false

    name    = aws_cognito_user_pool_domain.main.cloudfront_distribution
    zone_id = aws_cognito_user_pool_domain.main.cloudfront_distribution_zone_id
  }
  depends_on = [ aws_route53_record.parent ]
}

resource "aws_cognito_user_pool_client" "this" {
  name                                 = "${var.name}-client"
  user_pool_id                         = aws_cognito_user_pool.this.id
  allowed_oauth_flows                  = var.allowed_oauth_flows
  allowed_oauth_scopes                 = var.allowed_oauth_scopes
  supported_identity_providers         = var.supported_identity_providers
  allowed_oauth_flows_user_pool_client = true
  explicit_auth_flows                  = var.explicit_auth_flows
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls
  generate_secret                      = false

  access_token_validity  = var.access_token_validity
  id_token_validity      = var.id_token_validity
  refresh_token_validity = var.refresh_token_validity

  token_validity_units {
    access_token  = var.token_validity_units.access_token
    id_token      = var.token_validity_units.id_token
    refresh_token = var.token_validity_units.refresh_token
  }
}

resource "aws_cognito_identity_provider" "identity_providers" {
  for_each = var.identity_providers

  user_pool_id      = aws_cognito_user_pool.this.id
  provider_name     = each.value.provider_name
  provider_type     = each.value.provider_type
  provider_details  = each.value.provider_details
  attribute_mapping = each.value.attribute_mapping
}
