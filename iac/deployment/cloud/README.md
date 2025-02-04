# Cloud Infrastructure

Terraform module to deploy the cloud infrastructure for the deployment of the application.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| aws | 5.81.0 |
| github | ~> 6.4.0 |
| helm | 2.16.1 |
| kubernetes | 2.34.0 |

## Providers

| Name | Version |
|------|---------|
| aws | 5.81.0 |
| aws.virginia | 5.81.0 |
| external | 2.3.4 |
| kubernetes | 2.34.0 |
| random | 3.6.3 |
| tls | 4.0.6 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| acm\_main | terraform-aws-modules/acm/aws | ~> 4.3.2 |
| acm\_main\_virginia | terraform-aws-modules/acm/aws | ~> 4.3.2 |
| api | terraform-aws-modules/apigateway-v2/aws | ~> 5.2.1 |
| api\_sg | terraform-aws-modules/security-group/aws | ~> 5.2.0 |
| argocd | ../../modules/helm | n/a |
| atlantis | ../../modules/helm | n/a |
| atlantis\_custom\_pod\_identity | terraform-aws-modules/eks-pod-identity/aws | ~> 1.7.0 |
| aurora\_main | terraform-aws-modules/rds-aurora/aws | ~> 9.10.0 |
| avp\_custom\_pod\_identity | terraform-aws-modules/eks-pod-identity/aws | ~> 1.7.0 |
| aws\_cloudwatch\_observability\_pod\_identity | terraform-aws-modules/eks-pod-identity/aws | ~> 1.7.0 |
| aws\_ebs\_csi\_pod\_identity | terraform-aws-modules/eks-pod-identity/aws | ~> 1.7.0 |
| aws\_vpc\_cni\_ipv4\_pod\_identity | terraform-aws-modules/eks-pod-identity/aws | ~> 1.7.0 |
| bucket\_tfstate | terraform-aws-modules/s3-bucket/aws | ~> 4.2.2 |
| cognito\_pool | ../../modules/cognito | n/a |
| eks\_main | terraform-aws-modules/eks/aws | ~> 20.31.0 |
| kms\_main | terraform-aws-modules/kms/aws | ~> 3.1.1 |
| oidc\_github | unfunco/oidc-github/aws | 1.8.0 |
| repo\_phl | ../../modules/github | n/a |
| secrets\_iac | terraform-aws-modules/secrets-manager/aws | ~> 1.3.1 |
| vpc\_main | terraform-aws-modules/vpc/aws | ~> 5.16.0 |
| zones\_main | terraform-aws-modules/route53/aws//modules/zones | ~> 2.10.2 |

## Resources

| Name | Type |
|------|------|
| [kubernetes_storage_class_v1.gp3](https://registry.terraform.io/providers/hashicorp/kubernetes/2.34.0/docs/resources/storage_class_v1) | resource |
| [random_password.argocd_github_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.atlantis_github_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.atlantis_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [tls_private_key.argocd_ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.atlantis_ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/caller_identity) | data source |
| [aws_ecrpublic_authorization_token.token](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/ecrpublic_authorization_token) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy_document.atlantis_policy](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.avp_policy](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.custom_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/iam_policy_document) | data source |
| [aws_lb.alb](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/lb) | data source |
| [aws_lb_listener.listener](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/lb_listener) | data source |
| [aws_secretsmanager_secret_version.secret_iac_current](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/secretsmanager_secret_version) | data source |
| [external_external.is_running_on_ec2](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| argocd\_vault\_plugin\_version | ArgoCD Vault plugin version | `string` | n/a | yes |
| argocd\_version | ArgoCD version | `string` | n/a | yes |
| env | Stage environment where the infrastructure will be deployed. | `string` | n/a | yes |
| github\_oauth\_client\_id | Github OAuth client ID for ArgoCD | `string` | n/a | yes |
| github\_oauth\_client\_secret | Github OAuth client secret for ArgoCD | `string` | n/a | yes |
| github\_orgs | Github organization | `string` | n/a | yes |
| github\_owner | Github owner | `string` | n/a | yes |
| github\_repo | Github repository | `string` | n/a | yes |
| github\_secret | Github secret for ArgoCD | `string` | n/a | yes |
| region | The AWS region where resources will be created. | `string` | n/a | yes |
| unit | Business unit code. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| api\_authorizers | n/a |
| api\_endpoint | n/a |
| api\_id | API Gateway Outputs |
| api\_vpc\_links | n/a |
| aurora\_cluster\_endpoint | RDS Aurora Outputs |
| aurora\_cluster\_port | n/a |
| aurora\_cluster\_reader\_endpoint | n/a |
| aurora\_cluster\_username | n/a |
| cognito\_authrization\_scopes | n/a |
| cognito\_user\_pool\_arn | n/a |
| cognito\_user\_pool\_client\_id | n/a |
| cognito\_user\_pool\_client\_secret | n/a |
| cognito\_user\_pool\_endpoint | n/a |
| cognito\_user\_pool\_id | Cognito Outputs |
| dns\_name | Route 53 |
| eks\_cluster\_certificate\_authority\_data | n/a |
| eks\_cluster\_endpoint | n/a |
| eks\_cluster\_name | EKS Outputs |
| main\_key\_arn | n/a |
| main\_key\_id | KMS Outputs |
| route53\_zone\_arn | Route53 Outputs |
| tfstate\_bucket\_arn | n/a |
| tfstate\_bucket\_id | S3 Outputs |
<!-- END_TF_DOCS -->