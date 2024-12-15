module "external_dns_pod_identity" {
  source                        = "terraform-aws-modules/eks-pod-identity/aws"
  version                       = "~> 1.7.0"
  name                          = local.addon_standard.Feature
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [data.terraform_remote_state.cloud.outputs.route53_zone_arn["phl.blast.co.id"]]
  association_defaults = {
    namespace       = local.addon_standard.Feature
    service_account = "${local.addon_standard.Feature}-sa"
  }
  associations = {
    main = {
      cluster_name = data.terraform_remote_state.cloud.outputs.eks_cluster_name
    }
  }
  tags = local.tags
}

module "argocd_app" {
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
    source_origin_repoURL                  = "https://charts.bitnami.com/bitnami"
    source_origin_chart                    = local.addon_standard.Feature
    source_origin_targetRevision           = "8.3.8"
    source_override_repoURL                = "git@github.com:${var.github_owner}/${var.github_repo}.git"
    source_override_targetRevision         = "local"
    source_override_path                   = "gitops/charts/addons/${local.addon_standard.Feature}/values.yaml"
    project                                = "default"
    destination_server                     = "https://kubernetes.default.svc"
    destination_namespace                  = local.addon_standard.Feature
    syncPolicy_automated_prune             = true
    syncPolicy_automated_selfHeal          = true
    syncPolicy_syncOptions_CreateNamespace = true
  }
}

resource "kubernetes_secret_v1" "argocd" {
  count = var.add_repo_ssh_key_to_argocd ? 1 : 0
  metadata {
    name      = "cloudflare-api-key"
    namespace = local.addon_standard.Feature
  }

  data = {
    CF_API_EMAIL = "webmaster@blast.co.id"
    CF_API_KEY   = var.cloudflare_api_key
  }
}
