# Check whether the current environment is running on EC2 or not
data "external" "is_running_on_ec2" {
  program = ["bash", "-c", "curl -s -m 1 http://169.254.169.254/latest/meta-data/instance-id &>/dev/null && echo '{\"on_ec2\": \"true\"}' || echo '{\"on_ec2\": \"false\"}'"]
}

# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# Get availability zones
data "aws_availability_zones" "available" {}

# Get ECR public token from us-east-1
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}