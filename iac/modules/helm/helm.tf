# Create namespace
resource "kubernetes_namespace" "namespace" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
  }
}

locals {
  sa_naming_standard   = "${var.standard.Unit}-${var.standard.Env}-${var.standard.Code}-${var.standard.Feature}"
  helm_naming_standard = var.standard.Code == "svc" || var.standard.Code == "addon" ? "${var.standard.Unit}-${var.standard.Env}-${var.standard.Code}-${var.standard.Feature}" : "${var.standard.Unit}-${var.standard.Code}-${var.standard.Feature}"
  namespace            = var.create_namespace ? kubernetes_namespace.namespace[0].metadata[0].name : var.namespace
}

resource "helm_release" "helm" {
  name                = var.override_name != null ? var.override_name : local.helm_naming_standard
  repository          = var.repository
  repository_username = var.repository_username
  repository_password = var.repository_password
  chart               = var.chart
  version             = var.helm_version
  values = length(var.values) > 0 ? sensitive([
    "${templatefile(
      "manifest/${var.standard.Feature}.yaml",
      {
        service_account_name       = local.sa_naming_standard
        unit                       = var.standard.Unit
        code                       = var.standard.Code
        env                        = var.standard.Env
        feature                    = var.standard.Feature
        dns_name                   = var.dns_name
        service_account_annotation = var.create_gsa ? google_service_account.gsa[0].email : null
        extra_vars                 = var.extra_vars
      }
      )
    }"
  ]) : []
  namespace = local.namespace
  lint      = true
  dynamic "set" {
    for_each = length(var.helm_sets) > 0 ? {
      for helm_key, helm_set in var.helm_sets : helm_key => helm_set
    } : {}
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  dynamic "set_sensitive" {
    for_each = length(var.helm_sets_sensitive) > 0 ? {
      for helm_key, helm_set_sensitive in var.helm_sets_sensitive : helm_key => helm_set_sensitive
    } : {}
    content {
      name  = set_sensitive.value.name
      value = set_sensitive.value.value
    }
  }
  dynamic "set_list" {
    for_each = length(var.helm_sets_list) > 0 ? {
      for helm_key, helm_set_list in var.helm_sets_list : helm_key => helm_set_list
    } : {}
    content {
      name  = set_list.value.name
      value = set_list.value.value
    }
  }
}
