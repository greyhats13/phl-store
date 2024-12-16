# Service naming standard
variable "region" {
  type        = string
  description = "AWS region"
}

# Naming Standard
variable "unit" {
  type        = string
  description = "Business unit code"
}

variable "env" {
  type        = string
  description = "Stage environment"
}

variable "github_repo" {
  type        = string
  description = "Github repository name"
}

variable "github_owner" {
  type        = string
  description = "Github repository owner"
}

#Cloudflare
variable "cloudflare_api_key" {
  type        = string
  description = "Cloudflare API key"
  sensitive   = true
}
