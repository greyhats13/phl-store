locals {
  region = var.region
  tags = {
    GithubRepo = var.github_repo
    GithubOrg  = var.github_owner
  }
  addon_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "addon"
    Feature = "cert-manager"
  }
  addon_naming_standard = "${local.addon_standard.Unit}-${local.addon_standard.Code}-${local.addon_standard.Feature}"
  addon_naming_full     = "${local.addon_standard.Unit}-${local.addon_standard.Env}-${local.addon_standard.Code}-${local.addon_standard.Feature}"
  addon_name            = "${local.addon_standard.Unit}_${local.addon_standard.Feature}"
}
