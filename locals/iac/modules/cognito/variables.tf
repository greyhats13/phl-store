variable "region" {
  type        = string
  description = "AWS region"
}

variable "name" {
  type        = string
  description = "Base name for Cognito resources. User Pool, domain, and client will be derived from this."
}

variable "username_attributes" {
  type        = list(string)
  description = "Attributes supported as username by Cognito"
  default     = []
}

variable "auto_verified_attributes" {
  type        = list(string)
  description = "Auto verified attributes"
  default     = []
}

variable "password_policy" {
  type = object({
    minimum_length    = number
    require_lowercase = bool
    require_uppercase = bool
    require_numbers   = bool
    require_symbols   = bool
  })
  description = "Password policy configuration for the Cognito User Pool"
  default     = null
}

variable "domain" {
  type        = string
  description = "Cognito domain prefix"
  default     = null
}

variable "zone_id" {
  type        = string
  description = "Route 53 zone ID for the Cognito domain"
}

variable "alb_dns" {
  type        = string
  description = "alb dns name"
}

variable "alb_zone_id" {
  type        = string
  description = "alb zone id"
}

variable "certificate_arn" {
  type        = string
  description = "ARN of the certificate to use for the Cognito domain"
}

variable "allowed_oauth_flows" {
  type        = list(string)
  description = "Allowed OAuth flows"
  default     = []
}

# variable "allowed_oauth_scopes" {
#   type        = list(string)
#   description = "Allowed OAuth scopes"
#   default     = []
# }

variable "explicit_auth_flows" {
  type        = list(string)
  description = "Explicit auth flows"
  default = []

}

variable "supported_identity_providers" {
  type        = list(string)
  description = "Supported identity providers"
  default     = []
}

variable "allowed_oauth_flows_user_pool_client" {
  type        = bool
  description = "Whether the client is allowed to use the OAuth flow"
  default     = false
}

variable "generate_secret" {
  type        = bool
  description = "Whether to generate a client secret"
  default     = false
}

variable "callback_urls" {
  type        = list(string)
  description = "Allowed callback URLs for Cognito app client"
  default     = []
}

variable "logout_urls" {
  type        = list(string)
  description = "Allowed logout URLs for Cognito app client"
  default     = []
}

variable "token_validity_units" {
  type = object({
    access_token  = string
    id_token      = string
    refresh_token = string
  })
  description = "Token validity units"
  default = {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

variable "access_token_validity" {
  type        = number
  description = "Access token validity in minutes"
  default     = null
}

variable "id_token_validity" {
  type        = number
  description = "ID token validity in minutes"
  default     = null
}

variable "refresh_token_validity" {
  type        = number
  description = "Refresh token validity in days"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Extra tags to attach to Cognito resources"
  default     = {}
}

variable "identity_providers" {
  type = map(object({
    provider_name     = string
    provider_type     = string
    provider_details  = map(string)
    attribute_mapping = map(string)
  }))
  description = "Optional identity providers to attach to the User Pool"
  default     = {}
}

variable "resource_servers" {
  type = map(object({
    identifier = string
    name       = string
    scopes = list(object({
      scope_name        = string
      scope_description = string
    }))
  }))
  default = {}
}