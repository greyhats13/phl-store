locals {
  region = var.region
  tags = {
    GithubRepo = var.github_repo
    GithubOrg  = var.github_owner
  }
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
  # VPC Locals
  vpc_cidr     = "10.0.0.0/16"
  rfc6598_cidr = "100.64.0.0/16"
  azs = slice(data.aws_availability_zones.available.names, 0, length(data.aws_availability_zones.available.names))
  vpc_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "vpc"
    Feature = "main"
  }
  vpc_naming_standard = "${local.vpc_standard.Unit}-${local.vpc_standard.Env}-${local.vpc_standard.Code}-${local.vpc_standard.Feature}"
}
