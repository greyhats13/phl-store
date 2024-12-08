module "external_dns_pod_identity" {
  source                          = "terraform-aws-modules/eks-pod-identity/aws"
  version                         = "~> 1.7.0"
  name                            = local.addon_standard.Feature
  attach_aws_lb_controller_policy = true
  association_defaults = {
    namespace       = "kube-system"
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
    source_origin_repoURL                  = "https://aws.github.io/eks-charts"
    source_origin_chart                    = local.addon_standard.Feature
    source_origin_targetRevision           = "1.10.1"
    source_override_repoURL                = "git@github.com:${var.github_owner}/${var.github_repo}.git"
    source_override_targetRevision         = "main"
    source_override_path                   = "gitops/charts/addons/${local.addon_standard.Feature}/values.yaml"
    project                                = "default"
    destination_server                     = "https://kubernetes.default.svc"
    destination_namespace                  = "kube-system"
    syncPolicy_automated_prune             = true
    syncPolicy_automated_selfHeal          = true
    syncPolicy_syncOptions_CreateNamespace = false
  }
}
