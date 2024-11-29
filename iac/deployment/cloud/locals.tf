locals {
  region = var.region
  tags = {
    GithubRepo = var.github_repo
    GithubOrg  = var.github_owner
  }
  azs = slice(data.aws_availability_zones.available.names, 0, length(data.aws_availability_zones.available.names))
  # KMS Locals
  kms_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "kms"
    Feature = "main"
  }
  kms_naming_standard = "${local.kms_standard.Unit}-${local.kms_standard.Env}-${local.kms_standard.Code}-${local.kms_standard.Feature}"
  # S3 Locals
  s3_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "s3"
    Feature = "tfstate"
  }
  s3_naming_standard = "${local.s3_standard.Unit}-${local.s3_standard.Env}-${local.s3_standard.Code}-${local.s3_standard.Feature}"
}