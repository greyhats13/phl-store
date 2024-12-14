locals {
  is_ec2_environment = data.external.is_running_on_ec2.result["on_ec2"] == "true" ? true : false
}

terraform {
  backend "s3" {
    bucket = "phl-dev-s3-tfstate"
    key    = "phl/deployment/svc/phl-dev-deployment-svc-products.tfstate"
    region = "us-west-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.34.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }
    mysql = {
      source  = "petoju/mysql"
      version = "3.0.67"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.4.0"
    }
  }
}

# Create AWS provider
provider "aws" {
  region = local.region
  dynamic "assume_role" {
    # If the current environment is running on EC2 then use instance profile to access AWS resources
    for_each = local.is_ec2_environment ? [] : [1]
    content {
      role_arn = "arn:aws:iam::124456474132:role/iac"
    }
  }
}

# Create Kubernetes provider
provider "kubernetes" {
  host                   = data.terraform_remote_state.cloud.outputs.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.cloud.outputs.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Create Helm provider
provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.cloud.outputs.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.cloud.outputs.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "mysql" {
  endpoint = "${data.terraform_remote_state.cloud.outputs.aurora_cluster_endpoint}:${data.terraform_remote_state.cloud.outputs.aurora_cluster_port}"
  username = data.terraform_remote_state.cloud.outputs.aurora_cluster_username
  password = jsondecode(data.aws_secretsmanager_secret_version.aurora_password.secret_string)["password"]
}
