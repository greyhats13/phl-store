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
| kubernetes | 2.34.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| argocd\_app | ../../../modules/helm | n/a |

## Resources

| Name | Type |
|------|------|
| [kubernetes_secret_v1.argocd](https://registry.terraform.io/providers/hashicorp/kubernetes/2.34.0/docs/resources/secret_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloudflare\_api\_key | Cloudflare API key | `string` | n/a | yes |
| env | Stage environment | `string` | n/a | yes |
| github\_owner | Github repository owner | `string` | n/a | yes |
| github\_repo | Github repository name | `string` | n/a | yes |
| region | AWS region | `string` | n/a | yes |
| unit | Business unit code | `string` | n/a | yes |
<!-- END_TF_DOCS -->