# Create General purpose KMS key
module "kms_main" {
  source                = "terraform-aws-modules/kms/aws"
  version               = "~> 3.1.1"
  aliases               = ["main/${local.kms_naming_standard}"]
  description           = "${local.kms_naming_standard} cluster encryption key"
  enable_default_policy = true
  key_owners            = ["arn:aws:iam::124456474132:role/iac"]
  key_users             = ["arn:aws:iam::124456474132:user/iac"]
  key_service_roles_for_autoscaling = [
    # required for the ASG to manage encrypted volumes for nodes
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    # required for the cluster / persistentvolume-controller to create encrypted PVCs
    # module.eks_main.cluster_iam_role_arn
  ]
  tags = merge(local.tags, local.kms_standard, { Name = local.kms_naming_standard })
}

# Create S3 bucket for terraform state
module "bucket_tfstate" {
  source                   = "terraform-aws-modules/s3-bucket/aws"
  version                  = "~> 4.2.2"
  bucket                   = local.s3_naming_standard
  acl                      = "private"
  force_destroy            = true
  control_object_ownership = true
  object_ownership         = "ObjectWriter"
  attach_policy            = true
  policy                   = data.aws_iam_policy_document.custom_bucket_policy.json
  expected_bucket_owner    = data.aws_caller_identity.current.account_id
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = module.kms_main.key_arn
      }
    }
  }
  versioning = {
    enabled = true
  }

  tags = merge(local.tags, local.s3_standard, { Name = local.s3_naming_standard })
}

# Create AWS VPC architecture
module "vpc_main" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1.2"

  name                  = local.vpc_naming_standard
  cidr                  = local.vpc_cidr
  secondary_cidr_blocks = [local.rfc6598_cidr]
  azs                   = local.azs
  private_subnets = concat(
    [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 2, k)],
    [for k, v in local.azs : cidrsubnet(local.rfc6598_cidr, 3, k)]
  )
  database_subnets                                   = length(local.azs) <= 2 ? [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 16)] : [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 16)]
  public_subnets                                     = length(local.azs) <= 2 ? [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 18)] : [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 19)]
  enable_nat_gateway                                 = true
  single_nat_gateway                                 = var.env == "dev"? true : false
  one_nat_gateway_per_az                             = var.env == "dev"? false : true
  map_public_ip_on_launch                            = true
  private_subnet_names = concat(
    [for k, v in local.azs : "${local.vpc_naming_standard}-node-${v}"],
    # Custom network VPC CNI
    [for k, v in local.azs : "${local.vpc_naming_standard}-app-${v}"]
  )
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    # # Tags subnets for Karpenter auto-discovery
    # "karpenter.sh/discovery" = local.eks_naming_standard
  }
  tags = merge(local.tags, local.vpc_standard)
}