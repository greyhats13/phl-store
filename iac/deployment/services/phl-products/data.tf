# Check whether the current environment is running on EC2 or not
data "external" "is_running_on_ec2" {
  program = ["bash", "-c", "curl -s -m 1 http://169.254.169.254/latest/meta-data/instance-id &>/dev/null && echo '{\"on_ec2\": \"true\"}' || echo '{\"on_ec2\": \"false\"}'"]
}

# Get the current AWS account ID
data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "eks" {
  name = data.terraform_remote_state.cloud.outputs.eks_cluster_name
}

# Terraform state data kms cryptokey
data "terraform_remote_state" "cloud" {
  backend = "s3"

  config = {
    bucket  = "${var.unit}-${var.env}-s3-tfstate"
    key     = "${var.unit}/deployment/cloud/${var.unit}-${var.env}-deployment-cloud.tfstate"
    region  = var.region
    # profile = "${var.unit}-${var.env}"
  }
}

# Get the Aurora cluster password from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "aurora_password" {
  secret_id     = "rds!cluster-4f486f41-ab65-4060-b95d-a018a5abfc24"
  version_stage = "AWSCURRENT"
}

# Get eks cluster token
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.cloud.outputs.eks_cluster_name
}