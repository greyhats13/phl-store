# Databases Config
## Create a Database
resource "mysql_database" "db" {
  name = local.svc_naming_standard
}

## Create a Database User
resource "mysql_user" "db" {
  user               = local.svc_naming_standard
  host               = "%"
  plaintext_password = random_password.password.result
}

## Grant the user access to the database
resource "mysql_grant" "db" {
  user       = mysql_user.db.user
  host       = mysql_user.db.host
  database   = mysql_database.db.name
  privileges = ["CREATE", "SELECT", "INSERT", "UPDATE", "DELETE"]
}

# Secrets Manager
## Create Secrets Manager
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
    db_host           = data.terraform_remote_state.cloud.outputs.aurora_cluster_endpoint
    db_port           = data.terraform_remote_state.cloud.outputs.aurora_cluster_port
    db_name           = mysql_database.db.name
    db_user           = mysql_user.db.user
    db_password       = random_password.password.result
  })

  tags = merge(local.tags, local.svc_standard)
}

# CI/CD Components
module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.3.0"

  repository_name = local.svc_naming_standard
  repository_read_write_access_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/iac",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/atlantis-role",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
  repository_image_tag_mutability = "MUTABLE"
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
  manage_registry_scanning_configuration = true
  registry_scan_type                     = "BASIC"
  registry_scan_rules = [
    {
      scan_frequency = "SCAN_ON_PUSH"
      filter = [
        {
          filter      = "phl-*"
          filter_type = "WILDCARD"
        }
      ]
    }
  ]
  repository_encryption_type = "KMS"
  repository_kms_key         = data.terraform_remote_state.cloud.outputs.main_key_arn
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Prepare GIthub
module "github_action_env" {
  source                  = "../../../modules/github"
  repo_name               = var.github_repo
  owner                   = var.github_owner
  svc_name                = local.svc_naming_standard
  github_action_variables = local.github_action_variables
  # github_action_secrets   = local.github_action_secrets
}

## ArgoCD Vault Plugin (AVP) Pod Identity
module "svc_custom_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.7.0"

  name            = local.svc_naming_full
  use_name_prefix = false

  association_defaults = {
    namespace       = "app"
    service_account = local.svc_naming_full
    tags            = { App = "${local.svc_standard.Feature}" }
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

## Create ArgoCD App
module "argocd_app" {
  source     = "../../../modules/helm"
  region     = var.region
  standard   = local.svc_standard
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  values     = ["${file("manifest/${local.svc_standard.Feature}.yaml")}"]
  namespace  = "argocd"
  dns_name   = "${local.svc_standard.Feature}.${var.unit}.blast.co.id"
  extra_vars = {
    argocd_namespace                       = "argocd"
    source_repoURL                         = "git@github.com:${var.github_owner}/${var.github_repo}.git"
    source_targetRevision                  = "HEAD"
    source_path                            = "gitops/charts/app/${local.svc_name}"
    project                                = "default"
    destination_server                     = "https://kubernetes.default.svc"
    destination_namespace                  = var.env
    avp_type                               = "awssecretsmanager"
    region                                 = var.region
    syncPolicy_automated_prune             = true
    syncPolicy_automated_selfHeal          = true
    syncPolicy_syncOptions_CreateNamespace = true
  }
}

module "api_integration_routes" {
  source = "../../../modules/api"

  existing_gateway_id = data.terraform_remote_state.cloud.outputs.api_id
  # Custom domain
  create_domain_name             = false
  create_certificate             = false
  create_stage                   = false
  deploy_stage                   = false
  create_routes_and_integrations = true
  routes = {
    "GET /${local.svc_standard.Feature}" = {
      authorization_type     = "JWT"
      authorizer_key         = "cognito-authorizer"
      authorizer_id          = data.terraform_remote_state.cloud.outputs.api_authorizers["cognito"]["id"]
      authorization_scopes   = data.terraform_remote_state.cloud.outputs.cognito_authrization_scopes
      throttling_rate_limit  = 80
      throttling_burst_limit = 40

      integration = {
        connection_type = "VPC_LINK"
        connection_id   = data.terraform_remote_state.cloud.outputs.api_vpc_links["vpc-main"]["id"]
        type            = "HTTP_PROXY"
        method          = "GET"
        uri             = data.aws_lb_listener.listener.arn
        tls_config = {
          server_name_to_verify = "${local.svc_standard.Feature}.${data.terraform_remote_state.cloud.outputs.dns_name}"
        }
        request_parameters = {
          "overwrite:header.Host" = "${local.svc_standard.Feature}.${data.terraform_remote_state.cloud.outputs.dns_name}"
          "overwrite:path"        = "/api/${local.svc_standard.Feature}"
        }
      }
    }

    "POST /${local.svc_standard.Feature}" = {
      authorization_type     = "JWT"
      authorizer_key         = "cognito-authorizer"
      authorizer_id          = data.terraform_remote_state.cloud.outputs.api_authorizers["cognito"]["id"]
      authorization_scopes   = data.terraform_remote_state.cloud.outputs.cognito_authrization_scopes
      throttling_rate_limit  = 80
      throttling_burst_limit = 40

      integration = {
        connection_type = "VPC_LINK"
        connection_id   = data.terraform_remote_state.cloud.outputs.api_vpc_links["vpc-main"]["id"]
        type            = "HTTP_PROXY"
        method          = "POST"
        uri             = data.aws_lb_listener.listener.arn
        tls_config = {
          server_name_to_verify = "${local.svc_standard.Feature}.${data.terraform_remote_state.cloud.outputs.dns_name}"
        }
        request_parameters = {
          "overwrite:header.Host" = "${local.svc_standard.Feature}.${data.terraform_remote_state.cloud.outputs.dns_name}"
          "overwrite:path"        = "/api/${local.svc_standard.Feature}"
        }
        response_parameters = [
          {
            status_code = 200
            mappings = {
              "overwrite:statuscode" = "201"
            }
          }
        ]
      }
    }

    "GET /${local.svc_standard.Feature}/{id}" = {
      authorization_type     = "JWT"
      authorizer_key         = "cognito-authorizer"
      authorizer_id          = data.terraform_remote_state.cloud.outputs.api_authorizers["cognito"]["id"]
      authorization_scopes   = data.terraform_remote_state.cloud.outputs.cognito_authrization_scopes
      throttling_rate_limit  = 80
      throttling_burst_limit = 40

      integration = {
        connection_type = "VPC_LINK"
        connection_id   = data.terraform_remote_state.cloud.outputs.api_vpc_links["vpc-main"]["id"]
        type            = "HTTP_PROXY"
        method          = "GET"
        uri             = data.aws_lb_listener.listener.arn
        tls_config = {
          server_name_to_verify = "${local.svc_standard.Feature}.${data.terraform_remote_state.cloud.outputs.dns_name}"
        }
        request_parameters = {
          "overwrite:header.Host" = "${local.svc_standard.Feature}.${data.terraform_remote_state.cloud.outputs.dns_name}"
          "overwrite:path"        = "/api/${local.svc_standard.Feature}/$request.path.id"
        }
      }
    }

    "PUT /${local.svc_standard.Feature}/{id}" = {
      authorization_type     = "JWT"
      authorizer_key         = "cognito-authorizer"
      authorizer_id          = data.terraform_remote_state.cloud.outputs.api_authorizers["cognito"]["id"]
      authorization_scopes   = data.terraform_remote_state.cloud.outputs.cognito_authrization_scopes
      throttling_rate_limit  = 80
      throttling_burst_limit = 40

      integration = {
        connection_type = "VPC_LINK"
        connection_id   = data.terraform_remote_state.cloud.outputs.api_vpc_links["vpc-main"]["id"]
        type            = "HTTP_PROXY"
        method          = "PUT"
        uri             = data.aws_lb_listener.listener.arn
        tls_config = {
          server_name_to_verify = "${local.svc_standard.Feature}.${data.terraform_remote_state.cloud.outputs.dns_name}"
        }
        request_parameters = {
          "overwrite:header.Host" = "${local.svc_standard.Feature}.${data.terraform_remote_state.cloud.outputs.dns_name}"
          "overwrite:path"        = "/api/${local.svc_standard.Feature}/$request.path.id"
        }
      }
    }

    "DELETE /${local.svc_standard.Feature}/{id}" = {
      authorization_type     = "JWT"
      authorizer_key         = "cognito-authorizer"
      authorizer_id          = data.terraform_remote_state.cloud.outputs.api_authorizers["cognito"]["id"]
      authorization_scopes   = data.terraform_remote_state.cloud.outputs.cognito_authrization_scopes
      throttling_rate_limit  = 80
      throttling_burst_limit = 40

      integration = {
        connection_type = "VPC_LINK"
        connection_id   = data.terraform_remote_state.cloud.outputs.api_vpc_links["vpc-main"]["id"]
        type            = "HTTP_PROXY"
        method          = "DELETE"
        uri             = data.aws_lb_listener.listener.arn
        tls_config = {
          server_name_to_verify = "${local.svc_standard.Feature}.${data.terraform_remote_state.cloud.outputs.dns_name}"
        }
        request_parameters = {
          "overwrite:header.Host" = "${local.svc_standard.Feature}.${data.terraform_remote_state.cloud.outputs.dns_name}"
          "overwrite:path"        = "/api/${local.svc_standard.Feature}/$request.path.id"
        }
        response_parameters = [
          {
            status_code = 200
            mappings = {
              "overwrite:statuscode" = "204"
            }
          }
        ]
      }
    }

    # Already created
    # "$default" = {
    #   integration = {
    #     connection_type = "VPC_LINK"
    #     connection_id   = data.terraform_remote_state.cloud.outputs.api_vpc_links["vpc-main"]["id"]
    #     type            = "HTTP_PROXY"
    #     method          = "ANY"
    #     uri             = data.aws_lb_listener.listener.arn
    #     tls_config = {
    #       server_name_to_verify = "${local.svc_standard.Feature}.${data.terraform_remote_state.cloud.outputs.dns_name}"
    #     }
    #   }
    # }
  }
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
