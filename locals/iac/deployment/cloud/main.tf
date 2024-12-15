# ArgoCD
# ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes.
module "argocd" {
  source = "../../modules/helm"

  region           = var.region
  standard         = local.argocd_standard
  override_name    = local.argocd_standard.Feature
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  values           = ["${file("manifest/${local.argocd_standard.Feature}.yaml")}"]
  namespace        = local.argocd_standard.Feature
  create_namespace = true
  dns_name         = "local.blast.co.id"
  extra_vars = {
    github_orgs      = var.github_orgs
    github_client_id = var.github_oauth_client_id
    ARGOCD_VERSION   = var.argocd_version
    AVP_VERSION      = var.argocd_vault_plugin_version
    server_insecure  = true

    # ref https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd
    # ingress
    ingress_enabled    = false
    ingress_class_name = "nginx"
  }
}

# Setup repository for argocd and atlantis
module "repo_phl" {
  source                     = "../../modules/github"
  repo_name                  = var.github_repo
  owner                      = var.github_owner
  create_deploy_key          = true
  add_repo_ssh_key_to_argocd = true
  public_key                 = tls_private_key.argocd_ssh.public_key_openssh
  ssh_key                    = tls_private_key.argocd_ssh.private_key_pem
  is_deploy_key_read_only    = false
  argocd_namespace           = "argocd"
  depends_on = [
    module.argocd,
  ]
}

resource "cloudflare_dns_record" "example" {
  zone_id = var.cloudflare_zone_id
  name    = "argocd.local"
  value   = "172.0.0.1"
  type    = "A"
  ttl     = 300
}