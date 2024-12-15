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
| external | 2.3.4 |
| tls | 4.0.6 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| argocd | ../../modules/helm | n/a |
| repo\_phl | ../../modules/github | n/a |

## Resources

| Name | Type |
|------|------|
| [tls_private_key.argocd_ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
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
<!-- END_TF_DOCS -->