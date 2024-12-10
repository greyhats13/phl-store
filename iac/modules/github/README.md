<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider\_github) | ~> 6.4.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [github_actions_environment_secret.secret](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_secret) | resource |
| [github_actions_environment_variable.variable](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_variable) | resource |
| [github_repository_deploy_key.repository_deploy_key](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_deploy_key) | resource |
| [github_repository_environment.environment](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment) | resource |
| [github_repository_webhook.webhooks](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_webhook) | resource |
| [kubernetes_secret_v1.argocd](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_repo_ssh_key_to_argocd"></a> [add\_repo\_ssh\_key\_to\_argocd](#input\_add\_repo\_ssh\_key\_to\_argocd) | Set to true to add the repository SSH key to ArgoCD. | `bool` | `false` | no |
| <a name="input_argocd_namespace"></a> [argocd\_namespace](#input\_argocd\_namespace) | ArgoCD namespace | `string` | `null` | no |
| <a name="input_create_deploy_key"></a> [create\_deploy\_key](#input\_create\_deploy\_key) | Set to true to create a deploy key. | `bool` | `false` | no |
| <a name="input_github_action_secrets"></a> [github\_action\_secrets](#input\_github\_action\_secrets) | List of secrets to be added to the repository github actions | `map` | `{}` | no |
| <a name="input_github_action_variables"></a> [github\_action\_variables](#input\_github\_action\_variables) | List of environment variables to be added to the repository github actions | `map` | `{}` | no |
| <a name="input_is_deploy_key_read_only"></a> [is\_deploy\_key\_read\_only](#input\_is\_deploy\_key\_read\_only) | Set to true to create a read-only deploy key. | `bool` | `true` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The owner of the repository. | `string` | n/a | yes |
| <a name="input_public_key"></a> [public\_key](#input\_public\_key) | The public key to add to the repository. | `string` | `null` | no |
| <a name="input_repo_name"></a> [repo\_name](#input\_repo\_name) | The name of the repository. | `string` | n/a | yes |
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | The SSH key to add to the repository. | `string` | `null` | no |
| <a name="input_svc_name"></a> [svc\_name](#input\_svc\_name) | The name of the service. | `string` | `null` | no |
| <a name="input_webhooks"></a> [webhooks](#input\_webhooks) | Map of webhooks to be added to the repository | <pre>map(object({<br/>    configuration = object({<br/>      url          = string<br/>      content_type = string<br/>      insecure_ssl = bool<br/>      secret       = string<br/>    })<br/>    active = bool<br/>    events = list(string)<br/>  }))</pre> | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->