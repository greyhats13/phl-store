# Naming Standard
variable "region" {
  type        = string
  description = "The AWS region where resources will be created."
}

variable "unit" {
  type        = string
  description = "Business unit code."
}

variable "env" {
  type        = string
  description = "Stage environment where the infrastructure will be deployed."
}

# Terraform vars config

# Cloudflare
variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID"
}

variable "local_dns" {
  type        = string
  description = "Local DNS"
}

## Config
### Github
variable "github_owner" {
  type        = string
  description = "Github owner"
}

variable "github_orgs" {
  type        = string
  description = "Github organization"
}

variable "github_repo" {
  type        = string
  description = "Github repository"
}

variable "github_oauth_client_id" {
  type        = string
  description = "Github OAuth client ID for ArgoCD"
}

### Secrets
variable "github_oauth_client_secret" {
  type        = string
  description = "Github OAuth client secret for ArgoCD"
  sensitive   = true
}

variable "github_secret" {
  type       = string
  sensitive  = true
  description = "Github secret for ArgoCD"
}

# ### Atlantis

# variable "atlantis_version" {
#   type        = string
#   description = "Atlantis version"
# }

# variable "atlantis_user" {
#   type        = string
#   description = "Atlantis username"
# }

### ArgoCD
variable "argocd_version" {
  type        = string
  description = "ArgoCD version"
}

variable "argocd_vault_plugin_version" {
  type        = string
  description = "ArgoCD Vault plugin version"
}