<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cognito_identity_provider.identity_providers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_provider) | resource |
| [aws_cognito_resource_server.resource_servers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_resource_server) | resource |
| [aws_cognito_user_pool.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |
| [aws_cognito_user_pool_domain.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_domain) | resource |
| [aws_route53_record.child](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.parent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_token_validity"></a> [access\_token\_validity](#input\_access\_token\_validity) | Access token validity in minutes | `number` | `null` | no |
| <a name="input_alb_dns"></a> [alb\_dns](#input\_alb\_dns) | alb dns name | `string` | n/a | yes |
| <a name="input_alb_zone_id"></a> [alb\_zone\_id](#input\_alb\_zone\_id) | alb zone id | `string` | n/a | yes |
| <a name="input_allowed_oauth_flows"></a> [allowed\_oauth\_flows](#input\_allowed\_oauth\_flows) | Allowed OAuth flows | `list(string)` | `[]` | no |
| <a name="input_allowed_oauth_flows_user_pool_client"></a> [allowed\_oauth\_flows\_user\_pool\_client](#input\_allowed\_oauth\_flows\_user\_pool\_client) | Whether the client is allowed to use the OAuth flow | `bool` | `false` | no |
| <a name="input_auto_verified_attributes"></a> [auto\_verified\_attributes](#input\_auto\_verified\_attributes) | Auto verified attributes | `list(string)` | `[]` | no |
| <a name="input_callback_urls"></a> [callback\_urls](#input\_callback\_urls) | Allowed callback URLs for Cognito app client | `list(string)` | `[]` | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | ARN of the certificate to use for the Cognito domain | `string` | n/a | yes |
| <a name="input_domain"></a> [domain](#input\_domain) | Cognito domain prefix | `string` | `null` | no |
| <a name="input_explicit_auth_flows"></a> [explicit\_auth\_flows](#input\_explicit\_auth\_flows) | Explicit auth flows | `list(string)` | `[]` | no |
| <a name="input_generate_secret"></a> [generate\_secret](#input\_generate\_secret) | Whether to generate a client secret | `bool` | `false` | no |
| <a name="input_id_token_validity"></a> [id\_token\_validity](#input\_id\_token\_validity) | ID token validity in minutes | `number` | `null` | no |
| <a name="input_identity_providers"></a> [identity\_providers](#input\_identity\_providers) | Optional identity providers to attach to the User Pool | <pre>map(object({<br/>    provider_name     = string<br/>    provider_type     = string<br/>    provider_details  = map(string)<br/>    attribute_mapping = map(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_logout_urls"></a> [logout\_urls](#input\_logout\_urls) | Allowed logout URLs for Cognito app client | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Base name for Cognito resources. User Pool, domain, and client will be derived from this. | `string` | n/a | yes |
| <a name="input_password_policy"></a> [password\_policy](#input\_password\_policy) | Password policy configuration for the Cognito User Pool | <pre>object({<br/>    minimum_length    = number<br/>    require_lowercase = bool<br/>    require_uppercase = bool<br/>    require_numbers   = bool<br/>    require_symbols   = bool<br/>  })</pre> | `null` | no |
| <a name="input_refresh_token_validity"></a> [refresh\_token\_validity](#input\_refresh\_token\_validity) | Refresh token validity in days | `number` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_resource_servers"></a> [resource\_servers](#input\_resource\_servers) | n/a | <pre>map(object({<br/>    identifier = string<br/>    name       = string<br/>    scopes = list(object({<br/>      scope_name        = string<br/>      scope_description = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_supported_identity_providers"></a> [supported\_identity\_providers](#input\_supported\_identity\_providers) | Supported identity providers | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Extra tags to attach to Cognito resources | `map(string)` | `{}` | no |
| <a name="input_token_validity_units"></a> [token\_validity\_units](#input\_token\_validity\_units) | Token validity units | <pre>object({<br/>    access_token  = string<br/>    id_token      = string<br/>    refresh_token = string<br/>  })</pre> | <pre>{<br/>  "access_token": "minutes",<br/>  "id_token": "minutes",<br/>  "refresh_token": "days"<br/>}</pre> | no |
| <a name="input_username_attributes"></a> [username\_attributes](#input\_username\_attributes) | Attributes supported as username by Cognito | `list(string)` | `[]` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Route 53 zone ID for the Cognito domain | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cognito_authrization_scopes"></a> [cognito\_authrization\_scopes](#output\_cognito\_authrization\_scopes) | n/a |
| <a name="output_cognito_user_pool_arn"></a> [cognito\_user\_pool\_arn](#output\_cognito\_user\_pool\_arn) | n/a |
| <a name="output_cognito_user_pool_client_id"></a> [cognito\_user\_pool\_client\_id](#output\_cognito\_user\_pool\_client\_id) | n/a |
| <a name="output_cognito_user_pool_client_secret"></a> [cognito\_user\_pool\_client\_secret](#output\_cognito\_user\_pool\_client\_secret) | n/a |
| <a name="output_cognito_user_pool_domain"></a> [cognito\_user\_pool\_domain](#output\_cognito\_user\_pool\_domain) | n/a |
| <a name="output_cognito_user_pool_endpoint"></a> [cognito\_user\_pool\_endpoint](#output\_cognito\_user\_pool\_endpoint) | n/a |
| <a name="output_cognito_user_pool_id"></a> [cognito\_user\_pool\_id](#output\_cognito\_user\_pool\_id) | n/a |
<!-- END_TF_DOCS -->