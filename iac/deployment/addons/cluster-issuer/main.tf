module "argocd_app_k8s" {
  source     = "../../../modules/helm"
  region     = var.region
  standard   = local.addon_standard
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  values     = ["${file("manifest/${local.addon_standard.Feature}.yaml")}"]
  namespace  = "argocd"
  dns_name   = "${local.addon_standard.Feature}.${var.unit}.blast.co.id"
  extra_vars = {
    argocd_namespace                       = "argocd"
    source_repoURL                         = "git@github.com:${var.github_owner}/${var.github_repo}.git"
    source_targetRevision                  = "HEAD"
    source_path                            = "gitops/charts/addons/${local.addon_standard.Feature}"
    project                                = "default"
    destination_server                     = "https://kubernetes.default.svc"
    region                                 = var.region
    syncPolicy_automated_prune             = true
    syncPolicy_automated_selfHeal          = true
    syncPolicy_syncOptions_CreateNamespace = true
  }
}