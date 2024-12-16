<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.helm](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart"></a> [chart](#input\_chart) | helm chart | `string` | n/a | yes |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | create namespace | `bool` | `false` | no |
| <a name="input_dns_name"></a> [dns\_name](#input\_dns\_name) | dns name | `string` | `null` | no |
| <a name="input_extra_vars"></a> [extra\_vars](#input\_extra\_vars) | helm values extra vars | `map(any)` | `{}` | no |
| <a name="input_helm_sets"></a> [helm\_sets](#input\_helm\_sets) | list of helm set | `list(object({ name : string, value : any }))` | `[]` | no |
| <a name="input_helm_sets_list"></a> [helm\_sets\_list](#input\_helm\_sets\_list) | list of helm set list | `list(object({ name : string, value : list(string) }))` | `[]` | no |
| <a name="input_helm_sets_sensitive"></a> [helm\_sets\_sensitive](#input\_helm\_sets\_sensitive) | list of helm set sensitive | `list(object({ name : string, value : any }))` | `[]` | no |
| <a name="input_helm_version"></a> [helm\_version](#input\_helm\_version) | helm chart version | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | helm namespace | `string` | `null` | no |
| <a name="input_override_name"></a> [override\_name](#input\_override\_name) | override helm name | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | helm repository | `string` | n/a | yes |
| <a name="input_repository_password"></a> [repository\_password](#input\_repository\_password) | helm repository password | `string` | `null` | no |
| <a name="input_repository_username"></a> [repository\_username](#input\_repository\_username) | helm repository username | `string` | `null` | no |
| <a name="input_standard"></a> [standard](#input\_standard) | The standard naming convention for resources. | `map(string)` | `{}` | no |
| <a name="input_values"></a> [values](#input\_values) | helm values | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_k8s_ns_name"></a> [k8s\_ns\_name](#output\_k8s\_ns\_name) | n/a |
<!-- END_TF_DOCS -->