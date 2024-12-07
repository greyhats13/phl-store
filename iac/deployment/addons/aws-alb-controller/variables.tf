# Service naming standard
variable "region" {
  type        = string
  description = "GCP region"
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