# Github Settings

variable "repo_name" {
  type        = string
  description = "The name of the repository."
}

variable "owner" {
  type        = string
  description = "The owner of the repository."
}

variable "svc_name" {
  type        = string
  description = "The name of the service."
  default     = null

}

# Github webhooks arguments
variable "webhooks" {
  type = map(object({
    configuration = object({
      url          = string
      content_type = string
      insecure_ssl = bool
      secret       = string
    })
    active = bool
    events = list(string)
  }))
  description = "Map of webhooks to be added to the repository"
  default     = {}
}

# Github deploy key arguments

variable "add_repo_ssh_key_to_argocd" {
  type        = bool
  description = "Set to true to add the repository SSH key to ArgoCD."
  default     = false
}

variable "ssh_key" {
  type        = string
  description = "The SSH key to add to the repository."
  default     = null
}

variable "create_deploy_key" {
  description = "Set to true to create a deploy key."
  type        = bool
  default     = false
}

variable "public_key" {
  type        = string
  description = "The public key to add to the repository."
  default     = null
}

variable "is_deploy_key_read_only" {
  type        = bool
  description = "Set to true to create a read-only deploy key."
  default     = true
}

# Kubernetes arguments
variable "argocd_namespace" {
  type        = string
  description = "ArgoCD namespace"
  default     = null
}

# Github action arguments
variable "github_action_variables" {
  description = "List of environment variables to be added to the repository github actions"
  default     = {}
}

variable "github_action_secrets" {
  description = "List of secrets to be added to the repository github actions"
  default     = {}
}
