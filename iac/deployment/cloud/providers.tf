# if the current environment is running on EC2 then use instance profile to access AWS resources
# otherwise assume the iac role
locals {
  is_ec2_environment = data.external.is_running_on_ec2.result["on_ec2"] == "true" ? true : false
}

terraform {
  # backend "s3" {
  #   bucket = "phl-dev-s3-tfstate"
  #   key    = "phl/deployment/cloud/phl-dev-deployment-cloud.tfstate"
  #   region = "us-west-1"
  #   # profile = "phl-dev"
  # }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.34.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.18.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
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

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
  dynamic "assume_role" {
    for_each = local.is_ec2_environment ? [] : [1]
    content {
      role_arn = "arn:aws:iam::124456474132:role/iac"
    }
  }
}

# Create Kubernetes provider
provider "kubernetes" {
  host                   = module.eks_main.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_main.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "kubectl" {
  host                   = module.eks_main.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_main.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

# Create Helm provider
provider "helm" {
  kubernetes {
    host                   = module.eks_main.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_main.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
  # registry {
  #   url      = "oci://public.ecr.aws"
  #   username = data.aws_ecrpublic_authorization_token.token.user_name
  #   password = data.aws_ecrpublic_authorization_token.token.password
  # }
}
