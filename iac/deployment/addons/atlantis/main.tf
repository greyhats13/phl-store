module "external_dns_pod_identity" {
  source                        = "terraform-aws-modules/eks-pod-identity/aws"
  version                       = "~> 1.7.0"
  name                          = "${local.addon_standard.Feature}-role"
  use_name_prefix               = false
  external_dns_hosted_zone_arns = [data.terraform_remote_state.cloud.outputs.route53_zone_arn["phl.blast.co.id"]]
  association_defaults = {
    namespace       = local.addon_standard.Feature
    service_account = "${local.addon_standard.Feature}-sa"
    tags            = { App = local.addon_standard.Feature }
  }
  associations = {
    main = {
      cluster_name = data.terraform_remote_state.cloud.outputs.eks_cluster_name
    }
  }
  attach_custom_policy    = true
  source_policy_documents = [data.aws_iam_policy_document.atlantis_policy.json]
  tags                    = local.tags
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
    source_origin_repoURL                  = "https://runatlantis.github.io/helm-charts"
    source_origin_chart                    = local.addon_standard.Feature
    source_origin_targetRevision           = "5.11.0"
    source_override_repoURL                = "git@github.com:${var.github_owner}/${var.github_repo}.git"
    source_override_targetRevision         = "main"
    source_override_path                   = "gitops/charts/addons/${local.addon_standard.Feature}/values.yaml"
    project                                = "default"
    destination_server                     = "https://kubernetes.default.svc"
    destination_namespace                  = local.addon_standard.Feature
    syncPolicy_automated_prune             = true
    syncPolicy_automated_selfHeal          = true
    syncPolicy_syncOptions_CreateNamespace = true
  }
}
