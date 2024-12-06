# output "metadata" {
#   value = helm_release.helm.metadata
# }

output "k8s_ns_name" {
  value = var.create_namespace ? kubernetes_namespace.namespace[0].metadata[0].name : null
}