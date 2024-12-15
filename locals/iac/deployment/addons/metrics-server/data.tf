# Terraform state data kms cryptokey
data "terraform_remote_state" "cloud" {
  backend = "s3"

  config = {
    bucket  = "${var.unit}-${var.env}-s3-tfstate"
    key     = "${var.unit}/deployment/cloud/${var.unit}-${var.env}-deployment-cloud.tfstate"
    region  = var.region
  }
}

# Get eks cluster token
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.cloud.outputs.eks_cluster_name
}