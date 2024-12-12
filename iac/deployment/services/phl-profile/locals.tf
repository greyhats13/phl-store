locals {
  region = var.region
  tags = {
    GithubRepo = var.github_repo
    GithubOrg  = var.github_owner
  }
  svc_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "svc"
    Feature = "profile"
  }
  svc_naming_standard = "${local.svc_standard.Unit}-${local.svc_standard.Code}-${local.svc_standard.Feature}"
  svc_naming_full     = "${local.svc_standard.Unit}-${local.svc_standard.Env}-${local.svc_standard.Code}-${local.svc_standard.Feature}"
  svc_name            = "${local.svc_standard.Unit}-${local.svc_standard.Feature}"
  svc_secret_standard = "${local.svc_standard.Unit}/${local.svc_standard.Code}/${local.svc_standard.Unit}-${local.svc_standard.Feature}"
  ## Environment variables that will be stored in Github repo environment for Github Actions
  github_action_variables = {
    "${local.svc_standard.Feature}_svc_name"            = local.svc_name
    "${local.svc_standard.Feature}_svc_naming_standard" = local.svc_naming_standard
    "${local.svc_standard.Feature}_svc_naming_full"     = local.svc_naming_full
  }
  ## Environment secrets that will be stored in Github repo environment for Github Actions
  # github_action_secrets = {
  #   argocd_ssh = base64decode(jsondecode(data.aws_secretsmanager_secret_version.argocd_ssh.secret_string)["argocd_ssh_base64"])
  # }
}
