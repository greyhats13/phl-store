# Cloud Infrastructure

Terraform module to deploy the cloud infrastructure for the deployment of the application.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.80.0 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.4.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.16.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.34.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.80.0 |
| <a name="provider_aws.virginia"></a> [aws.virginia](#provider\_aws.virginia) | 5.80.0 |
| <a name="provider_external"></a> [external](#provider\_external) | 2.3.4 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.34.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.3 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.6 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm_main"></a> [acm\_main](#module\_acm\_main) | terraform-aws-modules/acm/aws | ~> 4.3.2 |
| <a name="module_acm_main_virginia"></a> [acm\_main\_virginia](#module\_acm\_main\_virginia) | terraform-aws-modules/acm/aws | ~> 4.3.2 |
| <a name="module_api"></a> [api](#module\_api) | terraform-aws-modules/apigateway-v2/aws | ~> 5.2.1 |
| <a name="module_api_sg"></a> [api\_sg](#module\_api\_sg) | terraform-aws-modules/security-group/aws | ~> 5.2.0 |
| <a name="module_argocd"></a> [argocd](#module\_argocd) | ../../modules/helm | n/a |
| <a name="module_atlantis"></a> [atlantis](#module\_atlantis) | ../../modules/helm | n/a |
| <a name="module_atlantis_custom_pod_identity"></a> [atlantis\_custom\_pod\_identity](#module\_atlantis\_custom\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 1.7.0 |
| <a name="module_aurora_main"></a> [aurora\_main](#module\_aurora\_main) | terraform-aws-modules/rds-aurora/aws | ~> 9.10.0 |
| <a name="module_avp_custom_pod_identity"></a> [avp\_custom\_pod\_identity](#module\_avp\_custom\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 1.7.0 |
| <a name="module_aws_cloudwatch_observability_pod_identity"></a> [aws\_cloudwatch\_observability\_pod\_identity](#module\_aws\_cloudwatch\_observability\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 1.7.0 |
| <a name="module_aws_ebs_csi_pod_identity"></a> [aws\_ebs\_csi\_pod\_identity](#module\_aws\_ebs\_csi\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 1.7.0 |
| <a name="module_aws_vpc_cni_ipv4_pod_identity"></a> [aws\_vpc\_cni\_ipv4\_pod\_identity](#module\_aws\_vpc\_cni\_ipv4\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 1.7.0 |
| <a name="module_bucket_tfstate"></a> [bucket\_tfstate](#module\_bucket\_tfstate) | terraform-aws-modules/s3-bucket/aws | ~> 4.2.2 |
| <a name="module_cognito_pool"></a> [cognito\_pool](#module\_cognito\_pool) | ../../modules/cognito | n/a |
| <a name="module_eks_main"></a> [eks\_main](#module\_eks\_main) | terraform-aws-modules/eks/aws | ~> 20.31.0 |
| <a name="module_kms_main"></a> [kms\_main](#module\_kms\_main) | terraform-aws-modules/kms/aws | ~> 3.1.1 |
| <a name="module_repo_phl"></a> [repo\_phl](#module\_repo\_phl) | ../../modules/github | n/a |
| <a name="module_secrets_iac"></a> [secrets\_iac](#module\_secrets\_iac) | terraform-aws-modules/secrets-manager/aws | ~> 1.3.1 |
| <a name="module_vpc_main"></a> [vpc\_main](#module\_vpc\_main) | terraform-aws-modules/vpc/aws | ~> 5.16.0 |
| <a name="module_zones_main"></a> [zones\_main](#module\_zones\_main) | terraform-aws-modules/route53/aws//modules/zones | ~> 2.10.2 |

## Resources

| Name | Type |
|------|------|
| [kubernetes_storage_class_v1.gp3](https://registry.terraform.io/providers/hashicorp/kubernetes/2.34.0/docs/resources/storage_class_v1) | resource |
| [random_password.argocd_github_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.atlantis_github_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.atlantis_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [tls_private_key.argocd_ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.atlantis_ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/5.80.0/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.80.0/docs/data-sources/caller_identity) | data source |
| [aws_ecrpublic_authorization_token.token](https://registry.terraform.io/providers/hashicorp/aws/5.80.0/docs/data-sources/ecrpublic_authorization_token) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/5.80.0/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy_document.atlantis_policy](https://registry.terraform.io/providers/hashicorp/aws/5.80.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.avp_policy](https://registry.terraform.io/providers/hashicorp/aws/5.80.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.custom_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/5.80.0/docs/data-sources/iam_policy_document) | data source |
| [aws_lb.alb](https://registry.terraform.io/providers/hashicorp/aws/5.80.0/docs/data-sources/lb) | data source |
| [aws_lb_listener.listener](https://registry.terraform.io/providers/hashicorp/aws/5.80.0/docs/data-sources/lb_listener) | data source |
| [aws_secretsmanager_secret_version.secret_iac_current](https://registry.terraform.io/providers/hashicorp/aws/5.80.0/docs/data-sources/secretsmanager_secret_version) | data source |
| [external_external.is_running_on_ec2](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_argocd_vault_plugin_version"></a> [argocd\_vault\_plugin\_version](#input\_argocd\_vault\_plugin\_version) | ArgoCD Vault plugin version | `string` | n/a | yes |
| <a name="input_argocd_version"></a> [argocd\_version](#input\_argocd\_version) | ArgoCD version | `string` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | Stage environment where the infrastructure will be deployed. | `string` | n/a | yes |
| <a name="input_github_oauth_client_id"></a> [github\_oauth\_client\_id](#input\_github\_oauth\_client\_id) | Github OAuth client ID for ArgoCD | `string` | n/a | yes |
| <a name="input_github_oauth_client_secret"></a> [github\_oauth\_client\_secret](#input\_github\_oauth\_client\_secret) | Github OAuth client secret for ArgoCD | `string` | n/a | yes |
| <a name="input_github_orgs"></a> [github\_orgs](#input\_github\_orgs) | Github organization | `string` | n/a | yes |
| <a name="input_github_owner"></a> [github\_owner](#input\_github\_owner) | Github owner | `string` | n/a | yes |
| <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo) | Github repository | `string` | n/a | yes |
| <a name="input_github_secret"></a> [github\_secret](#input\_github\_secret) | Github secret for ArgoCD | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region where resources will be created. | `string` | n/a | yes |
| <a name="input_unit"></a> [unit](#input\_unit) | Business unit code. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_authorizers"></a> [api\_authorizers](#output\_api\_authorizers) | n/a |
| <a name="output_api_endpoint"></a> [api\_endpoint](#output\_api\_endpoint) | n/a |
| <a name="output_api_id"></a> [api\_id](#output\_api\_id) | API Gateway Outputs |
| <a name="output_api_vpc_links"></a> [api\_vpc\_links](#output\_api\_vpc\_links) | n/a |
| <a name="output_aurora_cluster_endpoint"></a> [aurora\_cluster\_endpoint](#output\_aurora\_cluster\_endpoint) | RDS Aurora Outputs |
| <a name="output_aurora_cluster_port"></a> [aurora\_cluster\_port](#output\_aurora\_cluster\_port) | n/a |
| <a name="output_aurora_cluster_reader_endpoint"></a> [aurora\_cluster\_reader\_endpoint](#output\_aurora\_cluster\_reader\_endpoint) | n/a |
| <a name="output_aurora_cluster_username"></a> [aurora\_cluster\_username](#output\_aurora\_cluster\_username) | n/a |
| <a name="output_cognito_authrization_scopes"></a> [cognito\_authrization\_scopes](#output\_cognito\_authrization\_scopes) | n/a |
| <a name="output_cognito_user_pool_arn"></a> [cognito\_user\_pool\_arn](#output\_cognito\_user\_pool\_arn) | n/a |
| <a name="output_cognito_user_pool_client_id"></a> [cognito\_user\_pool\_client\_id](#output\_cognito\_user\_pool\_client\_id) | n/a |
| <a name="output_cognito_user_pool_client_secret"></a> [cognito\_user\_pool\_client\_secret](#output\_cognito\_user\_pool\_client\_secret) | n/a |
| <a name="output_cognito_user_pool_endpoint"></a> [cognito\_user\_pool\_endpoint](#output\_cognito\_user\_pool\_endpoint) | n/a |
| <a name="output_cognito_user_pool_id"></a> [cognito\_user\_pool\_id](#output\_cognito\_user\_pool\_id) | Cognito Outputs |
| <a name="output_dns_name"></a> [dns\_name](#output\_dns\_name) | Route 53 |
| <a name="output_eks_cluster_certificate_authority_data"></a> [eks\_cluster\_certificate\_authority\_data](#output\_eks\_cluster\_certificate\_authority\_data) | n/a |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | n/a |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | EKS Outputs |
| <a name="output_main_key_arn"></a> [main\_key\_arn](#output\_main\_key\_arn) | n/a |
| <a name="output_main_key_id"></a> [main\_key\_id](#output\_main\_key\_id) | KMS Outputs |
| <a name="output_route53_zone_arn"></a> [route53\_zone\_arn](#output\_route53\_zone\_arn) | Route53 Outputs |
| <a name="output_tfstate_bucket_arn"></a> [tfstate\_bucket\_arn](#output\_tfstate\_bucket\_arn) | n/a |
| <a name="output_tfstate_bucket_id"></a> [tfstate\_bucket\_id](#output\_tfstate\_bucket\_id) | S3 Outputs |
<!-- END_TF_DOCS -->