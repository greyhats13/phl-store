# Check whether the current environment is running on EC2 or not
data "external" "is_running_on_ec2" {
  program = ["bash", "-c", "curl -s -m 1 http://169.254.169.254/latest/meta-data/instance-id &>/dev/null && echo '{\"on_ec2\": \"true\"}' || echo '{\"on_ec2\": \"false\"}'"]
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

# Get eks cluster token
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.cloud.outputs.eks_cluster_name
}