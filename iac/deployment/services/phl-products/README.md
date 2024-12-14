<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| aws | 5.81.0 |
| helm | 2.16.1 |
| kubernetes | 2.34.0 |
| mysql | 3.0.67 |

## Providers

| Name | Version |
|------|---------|
| aws | 5.81.0 |
| external | 2.3.4 |
| mysql | 3.0.67 |
| random | 3.6.3 |
| terraform | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| api\_integration\_routes | ../../../modules/api | n/a |
| argocd\_app | ../../../modules/helm | n/a |
| secrets\_iac | terraform-aws-modules/secrets-manager/aws | ~> 1.3.1 |
| svc\_custom\_pod\_identity | terraform-aws-modules/eks-pod-identity/aws | ~> 1.7.0 |

## Resources

| Name | Type |
|------|------|
| [mysql_database.db](https://registry.terraform.io/providers/petoju/mysql/3.0.67/docs/resources/database) | resource |
| [mysql_grant.db](https://registry.terraform.io/providers/petoju/mysql/3.0.67/docs/resources/grant) | resource |
| [mysql_user.db](https://registry.terraform.io/providers/petoju/mysql/3.0.67/docs/resources/user) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/eks_cluster_auth) | data source |
| [aws_eks_cluster_auth.eks](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy_document.svc_policy](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/iam_policy_document) | data source |
| [aws_lb.selected](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/lb) | data source |
| [aws_lb_listener.listener](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/lb_listener) | data source |
| [aws_secretsmanager_secret_version.aurora_password](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/secretsmanager_secret_version) | data source |
| [external_external.is_running_on_ec2](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [terraform_remote_state.cloud](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| env | Stage environment | `string` | n/a | yes |
| github\_owner | Github repository owner | `string` | n/a | yes |
| github\_repo | Github repository name | `string` | n/a | yes |
| region | AWS region | `string` | n/a | yes |
| unit | Business unit code | `string` | n/a | yes |
<!-- END_TF_DOCS -->