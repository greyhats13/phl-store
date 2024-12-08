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
    Feature = "products"
  }
  svc_naming_standard = "${local.svc_standard.Unit}-${local.svc_standard.Code}-${local.svc_standard.Feature}"
  svc_naming_full     = "${local.svc_standard.Unit}-${local.svc_standard.Env}-${local.svc_standard.Code}-${local.svc_standard.Feature}"
  svc_name            = "${local.svc_standard.Unit}_${local.svc_standard.Feature}"
  svc_secret_standard = "${local.svc_standard.Unit}/${local.svc_standard.Code}/${local.svc_standard.Unit}-${local.svc_standard.Feature}"
  ## Environment variables that will be stored in Github repo environment for Github Actions
  github_action_variables = {
    service_name          = local.svc_name
    docker_repository_uri = "greyhats13/${local.svc_name}"
    gitops_repo_name      = var.github_repo
    repo_gitops_ssh       = "git@github.com:${var.github_owner}/${var.github_repo}.git"
    gitops_path_dev       = "gitops/charts/app/${local.svc_name}"
  }
  ## Secrets that will be stored in the Secret Manager
  app_secret = {
    "USERNAME" = "${local.svc_name}"
    "PASSWORD" = random_password.password.result
    "DATABASE" = local.svc_standard.Feature
    "HOST"     = data.terraform_remote_state.cloud.outputs.aurora_cluster_endpoint
    "PORT"     = data.terraform_remote_state.cloud.outputs.aurora_cluster_port
  }
}
