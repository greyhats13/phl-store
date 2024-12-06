resource "github_repository_webhook" "webhooks" {
  for_each   = length(var.webhooks) > 0 ? var.webhooks : {}
  repository = var.repo_name

  dynamic "configuration" {
    for_each = each.value.configuration != null ? [each.value.configuration] : []
    content {
      content_type = configuration.value.content_type
      insecure_ssl = configuration.value.insecure_ssl
      url          = configuration.value.url
      secret       = configuration.value.secret
    }
  }

  active = each.value.active

  events = each.value.events
}

resource "github_repository_deploy_key" "repository_deploy_key" {
  count      = var.create_deploy_key ? 1 : 0
  title      = "${var.repo_name}-public-key"
  repository = var.repo_name
  key        = var.public_key
  read_only  = var.is_deploy_key_read_only
}

resource "kubernetes_secret_v1" "argocd" {
  count = var.add_repo_ssh_key_to_argocd ? 1 : 0
  metadata {
    name      = var.repo_name
    namespace = var.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type          = "git"
    url           = "git@github.com:greyhats13/${var.repo_name}.git"
    sshPrivateKey = var.ssh_key
  }
}

resource "github_repository_environment" "environment" {
  count       = (length(var.github_action_secrets) > 0 || length(var.github_action_variables) > 0) ? 1 : 0
  environment = var.svc_name
  repository  = var.repo_name
}

resource "github_actions_environment_variable" "variable" {
  for_each      = var.github_action_variables
  repository    = var.repo_name
  environment   = github_repository_environment.environment[0].environment
  variable_name = each.key
  value         = each.value
}

resource "github_actions_environment_secret" "secret" {
  for_each        = tomap(var.github_action_secrets)
  repository      = var.repo_name
  environment     = github_repository_environment.environment[0].environment
  secret_name     = each.key
  plaintext_value = try(each.value.plaintext, each.value)
}
