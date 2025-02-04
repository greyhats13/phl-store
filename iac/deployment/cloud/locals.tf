locals {
  region = var.region
  tags = {
    Unit       = var.unit
    Env        = var.env
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
  # Route53 Locals
  route53_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "route53"
    Feature = "main"
  }
  route53_domain_name = "${var.unit}.blast.co.id"
  # ACM Locals
  acm_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "acm"
    Feature = "main"
  }
  acm_naming_standard = "${local.acm_standard.Unit}-${local.acm_standard.Env}-${local.acm_standard.Code}-${local.acm_standard.Feature}"
  # Secrets Manager Locals
  secrets_manager_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "secretsmanager"
    Feature = "iac"
  }
  secrets_manager_naming_standard = "${local.secrets_manager_standard.Unit}/${local.secrets_manager_standard.Env}/${local.secrets_manager_standard.Code}/${local.secrets_manager_standard.Feature}"
  # VPC Locals
  vpc_cidr     = "10.0.0.0/16"
  rfc6598_cidr = "100.64.0.0/16"
  service_cidr = "10.1.0.0/16"
  azs          = slice(data.aws_availability_zones.available.names, 0, length(data.aws_availability_zones.available.names))
  vpc_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "vpc"
    Feature = "main"
  }
  vpc_naming_standard = "${local.vpc_standard.Unit}-${local.vpc_standard.Env}-${local.vpc_standard.Code}-${local.vpc_standard.Feature}"
  # EKS Locals
  eks_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "eks"
    Feature = "main"
  }
  eks_naming_standard = "${local.eks_standard.Unit}-${local.eks_standard.Env}-${local.eks_standard.Code}-${local.eks_standard.Feature}"
  cluster_version     = "1.31"
  eks_workload_type   = "ec2"
  # ArgoCD Locals
  argocd_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "addon"
    Feature = "argocd"
  }
  argocd_naming_standard = "${local.argocd_standard.Unit}-${local.argocd_standard.Env}-${local.argocd_standard.Code}-${local.argocd_standard.Feature}"
  # Atlantis Locals
  atlantis_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "addon"
    Feature = "atlantis"
  }
  atlantis_naming_standard = "${local.atlantis_standard.Unit}-${local.atlantis_standard.Env}-${local.atlantis_standard.Code}-${local.atlantis_standard.Feature}"
  # Aurora Locals
  aurora_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "rds-aurora"
    Feature = "main"
  }
  aurora_naming_standard = "${local.aurora_standard.Unit}-${local.aurora_standard.Env}-${local.aurora_standard.Code}-${local.aurora_standard.Feature}"
  # Cognito User Pool Locals
  cognito_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "cognito"
    Feature = "main"
  }
  cognito_naming_standard = "${local.cognito_standard.Unit}-${local.cognito_standard.Env}-${local.cognito_standard.Code}-${local.cognito_standard.Feature}"
  # API Gateway Locals
  api_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "api"
    Feature = "main"
  }
  api_naming_standard = "${local.api_standard.Unit}-${local.api_standard.Env}-${local.api_standard.Code}-${local.api_standard.Feature}"
}
