module "argocd_app" {
  source        = "../../../modules/helm"
  region        = var.region
  standard      = local.addon_standard
  override_name = local.addon_standard.Feature
  repository    = "https://argoproj.github.io/argo-helm"
  chart         = "argocd-apps"
  values        = ["${file("manifest/${local.addon_standard.Feature}.yaml")}"]
  namespace     = "argocd"
  dns_name      = "${local.addon_standard.Feature}.blast.co.id"
  extra_vars = {
    argocd_namespace                       = "argocd"
    source_origin_repoURL                  = "https://kubernetes-sigs.github.io/metrics-server/"
    source_origin_chart                    = local.addon_standard.Feature
    source_origin_targetRevision           = "3.12.2"
    source_override_repoURL                = "git@github.com:${var.github_owner}/${var.github_repo}.git"
    source_override_targetRevision         = "local"
    source_override_path                   = "locals/gitops/charts/addons/${local.addon_standard.Feature}/values.yaml"
    project                                = "default"
    destination_server                     = "https://kubernetes.default.svc"
    destination_namespace                  = "kube-system"
    syncPolicy_automated_prune             = true
    syncPolicy_automated_selfHeal          = true
    syncPolicy_syncOptions_CreateNamespace = true
  }
}
