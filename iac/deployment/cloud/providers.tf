# if the current environment is running on EC2 then use instance profile to access AWS resources
# otherwise assume the iac role
locals {
  is_ec2_environment = data.external.is_running_on_ec2.result["on_ec2"] == "true" ? true : false
}

terraform {
  backend "s3" {
    bucket  = "phl-dev-s3-tfstate"
    key     = "phl/deployment/cloud/phl-dev-deployment-cloud.tfstate"
    region  = "us-west-1"
    # profile = "phl-dev"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.80.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.34.0"
    }
  }
}

# Create AWS provider
provider "aws" {
  region = local.region
  # profile = "${var.unit}-${var.env}"
  dynamic "assume_role" {
    # If the current environment is running on EC2 then use instance profile to access AWS resources
    for_each = local.is_ec2_environment ? [] : [1]
    content {
      role_arn = "arn:aws:iam::124456474132:role/iac"
    }
  }
}