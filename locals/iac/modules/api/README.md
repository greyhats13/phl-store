# API Gateway Custom
This is personal module by removing the needs to create aws_apigatewayv2_api, so I can separate the creation of the API Gateway and the routes.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| aws | >= 5.37 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.37 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| acm | terraform-aws-modules/acm/aws | 5.0.1 |

## Resources

| Name | Type |
|------|------|
| [aws_apigatewayv2_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_api_mapping.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api_mapping) | resource |
| [aws_apigatewayv2_authorizer.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_authorizer) | resource |
| [aws_apigatewayv2_deployment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_deployment) | resource |
| [aws_apigatewayv2_domain_name.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_domain_name) | resource |
| [aws_apigatewayv2_integration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_integration_response.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration_response) | resource |
| [aws_apigatewayv2_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route_response.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route_response) | resource |
| [aws_apigatewayv2_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_apigatewayv2_vpc_link.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_vpc_link) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| api\_key\_selection\_expression | An API key selection expression. Valid values: `$context.authorizer.usageIdentifierKey`, `$request.header.x-api-key`. Defaults to `$request.header.x-api-key`. Applicable for WebSocket APIs | `string` | `null` | no |
| api\_mapping\_key | The [API mapping key](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-mapping-template-reference.html) | `string` | `null` | no |
| api\_version | A version identifier for the API. Must be between 1 and 64 characters in length | `string` | `null` | no |
| authorizers | Map of API gateway authorizers to create | ```map(object({ authorizer_credentials_arn = optional(string) authorizer_payload_format_version = optional(string) authorizer_result_ttl_in_seconds = optional(number) authorizer_type = optional(string, "REQUEST") authorizer_uri = optional(string) enable_simple_responses = optional(bool) identity_sources = optional(list(string)) jwt_configuration = optional(object({ audience = optional(list(string)) issuer = optional(string) })) name = optional(string) }))``` | `{}` | no |
| body | An OpenAPI specification that defines the set of routes and integrations to create as part of the HTTP APIs. Supported only for HTTP APIs | `string` | `null` | no |
| cors\_configuration | The cross-origin resource sharing (CORS) configuration. Applicable for HTTP APIs | ```object({ allow_credentials = optional(bool) allow_headers = optional(list(string)) allow_methods = optional(list(string)) allow_origins = optional(list(string)) expose_headers = optional(list(string), []) max_age = optional(number) })``` | `null` | no |
| create | Controls if resources should be created | `bool` | `true` | no |
| create\_certificate | Whether to create a certificate for the domain | `bool` | `true` | no |
| create\_domain\_name | Whether to create API domain name resource | `bool` | `true` | no |
| create\_domain\_records | Whether to create Route53 records for the domain name | `bool` | `true` | no |
| create\_routes\_and\_integrations | Whether to create routes and integrations resources | `bool` | `true` | no |
| create\_stage | Whether to create default stage | `bool` | `true` | no |
| credentials\_arn | Part of quick create. Specifies any credentials required for the integration. Applicable for HTTP APIs | `string` | `null` | no |
| deploy\_stage | Whether to deploy the stage. `HTTP` APIs are auto-deployed by default | `bool` | `true` | no |
| description | The description of the API. Must be less than or equal to 1024 characters in length | `string` | `null` | no |
| disable\_execute\_api\_endpoint | Whether clients can invoke the API by using the default execute-api endpoint. By default, clients can invoke the API with the default `{api_id}.execute-api.{region}.amazonaws.com endpoint`. To require that clients use a custom domain name to invoke the API, disable the default endpoint | `bool` | `null` | no |
| domain\_name | The domain name to use for API gateway | `string` | `""` | no |
| domain\_name\_certificate\_arn | The ARN of an AWS-managed certificate that will be used by the endpoint for the domain name. AWS Certificate Manager is the only supported source | `string` | `null` | no |
| domain\_name\_ownership\_verification\_certificate\_arn | ARN of the AWS-issued certificate used to validate custom domain ownership (when certificate\_arn is issued via an ACM Private CA or mutual\_tls\_authentication is configured with an ACM-imported certificate.) | `string` | `null` | no |
| existing\_gateway\_id | The ID of the API Gateway to manage | `string` | `null` | no |
| fail\_on\_warnings | Whether warnings should return an error while API Gateway is creating or updating the resource using an OpenAPI specification. Defaults to `false`. Applicable for HTTP APIs | `bool` | `null` | no |
| hosted\_zone\_name | Optional domain name of the Hosted Zone where the domain should be created | `string` | `null` | no |
| mutual\_tls\_authentication | The mutual TLS authentication configuration for the domain name | `map(string)` | `{}` | no |
| name | The name of the API. Must be less than or equal to 128 characters in length | `string` | `""` | no |
| protocol\_type | The API protocol. Valid values: `HTTP`, `WEBSOCKET` | `string` | `"HTTP"` | no |
| route\_key | Part of quick create. Specifies any route key. Applicable for HTTP APIs | `string` | `null` | no |
| route\_selection\_expression | The route selection expression for the API. Defaults to `$request.method $request.path` | `string` | `null` | no |
| routes | Map of API gateway routes with integrations | ```map(object({ # Route authorizer_key = optional(string) api_key_required = optional(bool) authorization_scopes = optional(list(string), []) authorization_type = optional(string) authorizer_id = optional(string) model_selection_expression = optional(string) operation_name = optional(string) request_models = optional(map(string), {}) request_parameter = optional(object({ request_parameter_key = optional(string) required = optional(bool, false) }), {}) route_response_selection_expression = optional(string) # Route settings data_trace_enabled = optional(bool) detailed_metrics_enabled = optional(bool) logging_level = optional(string) throttling_burst_limit = optional(number) throttling_rate_limit = optional(number) # Stage - Route response route_response = optional(object({ create = optional(bool, false) model_selection_expression = optional(string) response_models = optional(map(string)) route_response_key = optional(string, "$default") }), {}) # Integration integration = object({ connection_id = optional(string) vpc_link_key = optional(string) connection_type = optional(string) content_handling_strategy = optional(string) credentials_arn = optional(string) description = optional(string) method = optional(string) subtype = optional(string) type = optional(string, "AWS_PROXY") uri = optional(string) passthrough_behavior = optional(string) payload_format_version = optional(string) request_parameters = optional(map(string), {}) request_templates = optional(map(string), {}) response_parameters = optional(list(object({ mappings = map(string) status_code = string }))) template_selection_expression = optional(string) timeout_milliseconds = optional(number) tls_config = optional(object({ server_name_to_verify = optional(string) })) # Integration Response response = optional(object({ content_handling_strategy = optional(string) integration_response_key = optional(string) response_templates = optional(map(string)) template_selection_expression = optional(string) }), {}) }) }))``` | `{}` | no |
| stage\_access\_log\_settings | Settings for logging access in this stage. Use the aws\_api\_gateway\_account resource to configure [permissions for CloudWatch Logging](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html#set-up-access-logging-permissions) | ```object({ create_log_group = optional(bool, true) destination_arn = optional(string) format = optional(string) log_group_name = optional(string) log_group_retention_in_days = optional(number, 30) log_group_kms_key_id = optional(string) log_group_skip_destroy = optional(bool) log_group_class = optional(string) log_group_tags = optional(map(string), {}) })``` | `{}` | no |
| stage\_client\_certificate\_id | The identifier of a client certificate for the stage. Use the `aws_api_gateway_client_certificate` resource to configure a client certificate. Supported only for WebSocket APIs | `string` | `null` | no |
| stage\_default\_route\_settings | The default route settings for the stage | ```object({ data_trace_enabled = optional(bool, true) detailed_metrics_enabled = optional(bool, true) logging_level = optional(string) throttling_burst_limit = optional(number, 500) throttling_rate_limit = optional(number, 1000) })``` | `{}` | no |
| stage\_description | The description for the stage. Must be less than or equal to 1024 characters in length | `string` | `null` | no |
| stage\_name | The name of the stage. Must be between 1 and 128 characters in length | `string` | `"$default"` | no |
| stage\_tags | A mapping of tags to assign to the stage resource | `map(string)` | `{}` | no |
| stage\_variables | A map that defines the stage variables for the stage | `map(string)` | `{}` | no |
| subdomain\_record\_types | A list of record types to create for the subdomain(s) | `list(string)` | ```[ "A", "AAAA" ]``` | no |
| subdomains | An optional list of subdomains to use for API gateway | `list(string)` | `[]` | no |
| tags | A mapping of tags to assign to API gateway resources | `map(string)` | `{}` | no |
| target | Part of quick create. Quick create produces an API with an integration, a default catch-all route, and a default stage which is configured to automatically deploy changes. For HTTP integrations, specify a fully qualified URL. For Lambda integrations, specify a function ARN. The type of the integration will be HTTP\_PROXY or AWS\_PROXY, respectively. Applicable for HTTP APIs | `string` | `null` | no |
| vpc\_link\_tags | A map of tags to add to the VPC Links created | `map(string)` | `{}` | no |
| vpc\_links | Map of VPC Link definitions to create | ```map(object({ name = optional(string) security_group_ids = optional(list(string)) subnet_ids = optional(list(string)) tags = optional(map(string), {}) }))``` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| acm\_certificate\_arn | The ARN of the certificate |
| api\_arn | The ARN of the API |
| api\_endpoint | URI of the API, of the form `https://{api-id}.execute-api.{region}.amazonaws.com` for HTTP APIs and `wss://{api-id}.execute-api.{region}.amazonaws.com` for WebSocket APIs |
| api\_execution\_arn | The ARN prefix to be used in an `aws_lambda_permission`'s `source_arn` attribute or in an `aws_iam_policy` to authorize access to the `@connections` API |
| api\_id | The API identifier |
| authorizers | Map of API Gateway Authorizer(s) created and their attributes |
| domain\_name\_api\_mapping\_selection\_expression | The API mapping selection expression for the domain name |
| domain\_name\_arn | The ARN of the domain name |
| domain\_name\_configuration | The domain name configuration |
| domain\_name\_hosted\_zone\_id | The Amazon Route 53 Hosted Zone ID of the endpoint |
| domain\_name\_id | The domain name identifier |
| domain\_name\_target\_domain\_name | The target domain name |
| integrations | Map of the integrations created and their attributes |
| routes | Map of the routes created and their attributes |
| stage\_access\_logs\_cloudwatch\_log\_group\_arn | Arn of cloudwatch log group created |
| stage\_access\_logs\_cloudwatch\_log\_group\_name | Name of cloudwatch log group created |
| stage\_arn | The stage ARN |
| stage\_domain\_name | Domain name of the stage (useful for CloudFront distribution) |
| stage\_execution\_arn | The ARN prefix to be used in an aws\_lambda\_permission's source\_arn attribute or in an aws\_iam\_policy to authorize access to the @connections API |
| stage\_id | The stage identifier |
| stage\_invoke\_url | The URL to invoke the API pointing to the stage |
| vpc\_links | Map of VPC links created and their attributes |
<!-- END_TF_DOCS -->