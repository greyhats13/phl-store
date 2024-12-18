# Check whether the current environment is running on EC2 or not
data "external" "is_running_on_ec2" {
  program = ["bash", "-c", "curl -s -m 1 http://169.254.169.254/latest/meta-data/instance-id &>/dev/null && echo '{\"on_ec2\": \"true\"}' || echo '{\"on_ec2\": \"false\"}'"]
}

# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# Get availability zones
data "aws_availability_zones" "available" {}

# Get AWS Secrets Manager current version
data "aws_secretsmanager_secret_version" "secret_iac_current" {
  secret_id     = module.secrets_iac.secret_id
  version_stage = "AWSCURRENT"
}

# Get ECR public token from us-east-1
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

Get eks cluster token
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_main.cluster_name
}

Get AWS ALB DNS name
data "aws_lb" "alb" {
  name = "k8s-phldevaddoningres-009c2e8ab5"
}

data "aws_lb_listener" "listener" {
  load_balancer_arn = data.aws_lb.alb.arn
  port              = 443
}
