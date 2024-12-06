# GCP Settings
variable "region" {
  type        = string
  description = "AWS region"
}

variable "standard" {
  type        = map(string)
  description = "The standard naming convention for resources."
  default     = {}
}

# helm arguments

variable "override_name" {
  type        = string
  description = "override helm name"
  default     = null
}

variable "repository" {
  type        = string
  description = "helm repository"
}

variable "repository_username" {
  type        = string
  description = "helm repository username"
  default     = null
}

variable "repository_password" {
  type        = string
  description = "helm repository password"
  default     = null
}

variable "chart" {
  type        = string
  description = "helm chart"
}

variable "helm_version" {
  type        = string
  description = "helm chart version"
  default     = null
}

variable "values" {
  type        = list(string)
  description = "helm values"
  default     = []
}

variable "namespace" {
  type        = string
  description = "helm namespace"
  default     = null
}

variable "create_namespace" {
  type        = bool
  description = "create namespace"
  default     = false
}

variable "dns_name" {
  type        = string
  description = "dns name"
  default     = null
}

variable "helm_sets" {
  type        = list(object({ name : string, value : any }))
  description = "list of helm set"
  default     = []
}

variable "helm_sets_sensitive" {
  type        = list(object({ name : string, value : any }))
  description = "list of helm set sensitive"
  default     = []
}

variable "helm_sets_list" {
  type        = list(object({ name : string, value : list(string) }))
  description = "list of helm set list"
  default     = []
}

variable "extra_vars" {
  type        = map(any)
  description = "helm values extra vars"
  default     = {}
  sensitive   = true
}
