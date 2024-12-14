<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| aws | 5.81.0 |
| helm | 2.16.1 |
| kubernetes | 2.34.0 |

## Providers

| Name | Version |
|------|---------|
| aws | 5.81.0 |
| external | 2.3.4 |
| terraform | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| argocd\_app | ../../../modules/helm | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/eks_cluster_auth) | data source |
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