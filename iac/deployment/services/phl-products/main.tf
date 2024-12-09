# Create a Database
resource "mysql_database" "db" {
  name = local.svc_naming_standard
}

resource "mysql_user" "db" {
  user               = local.svc_naming_standard
  host               = "%"
  plaintext_password = random_password.password.result
}

resource "mysql_grant" "db" {
  user       = mysql_user.db.user
  host       = mysql_user.db.host
  database   = mysql_database.db.name
  privileges = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

# Create Secrets Manager
module "secrets_iac" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "~> 1.3.1"

  # Secret
  name                    = local.svc_secret_standard
  description             = "Secrets for ${local.svc_secret_standard}"
  recovery_window_in_days = 0

  # Policy
  create_policy       = true
  block_public_policy = true
  policy_statements = {
    admin = {
      sid = "IacSecretAdmin"
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
        },
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/imam.arief.rhmn@gmail.com"]
        },
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/idanfreak@gmail.com"]
        },
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/iac"]
        },
      ]
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["*"]
    }
  }

  # Version
  ignore_secret_changes = false
  secret_string = jsonencode({
    connection_string = "${mysql_user.db.user}:${random_password.password.result}@tcp(${data.terraform_remote_state.cloud.outputs.aurora_cluster_endpoint}:${data.terraform_remote_state.cloud.outputs.aurora_cluster_port})/${mysql_database.db.name}"
    port              = "8080"
  })

  tags = merge(local.tags, local.svc_standard)
}

# ArgoCD Vault Plugin (AVP) Pod Identity
module "svc_custom_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.7.0"

  name            = local.svc_naming_full
  use_name_prefix = false

  association_defaults = {
    namespace       = "app"
    service_account = local.svc_naming_full
    tags            = { App = "products" }
  }

  associations = {
    main = {
      cluster_name = data.terraform_remote_state.cloud.outputs.eks_cluster_name
    }
  }

  attach_custom_policy    = true
  source_policy_documents = [data.aws_iam_policy_document.svc_policy.json]

  tags = local.tags
}

# module "argocd_app" {
#   source        = "../../../modules/helm"
#   region        = var.region
#   standard      = local.svc_standard
#   repository    = "https://argoproj.github.io/argo-helm"
#   chart         = "argocd-apps"
#   values        = ["${file("manifest/${local.svc_standard.Feature}.yaml")}"]
#   namespace     = "argocd"
#   dns_name      = "${local.svc_standard.Feature}.${var.unit}.blast.co.id"
#   extra_vars = {
#     argocd_namespace                       = "argocd"
#     source_repoURL                         = "git@github.com:${var.github_owner}/${var.github_repo}.git"
#     source_targetRevision                  = "HEAD"
#     source_path                            = "gitops/charts/app/${local.svc_name}"
#     project                                = "default"
#     destination_server                     = "https://kubernetes.default.svc"
#     destination_namespace                  = var.env
#     avp_type                               = "awssecretsmanager"
#     region                                 = var.region
#     syncPolicy_automated_prune             = true
#     syncPolicy_automated_selfHeal          = true
#     syncPolicy_syncOptions_CreateNamespace = true
#   }
# }
