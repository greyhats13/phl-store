
# Create terraform state
terraform {
  backend "s3" {
    bucket  = "ols-mstr-stor-s3-tfstate"
    key     = "aws/cloud/ols-mstr-cloud-resources.tfstate"
    region  = "us-west-1"
    profile = "ols-mstr"
  }
}

# Create General purpose KMS key
module "kms_main" {
  source                = "terraform-aws-modules/kms/aws"
  version               = "~> 2.0.1"
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
  version                  = "~> 3.15.1"
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


# Create keypair for SSH access
module "keypair_main" {
  source                = "terraform-aws-modules/key-pair/aws"
  version               = "~> 2.0.2"
  key_name              = "deployer-one"
  create_private_key    = true
  private_key_algorithm = "RSA"
  private_key_rsa_bits  = 2048
}

# Create SSM parameters for infrastructure config and secrets
module "ssm_params" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "~> 1.1.0"

  for_each = local.parameters

  name            = "${local.ssm_naming_standard}/${split("_", each.key)[0]}/${upper(each.key)}"
  value           = try(each.value.value, null)
  values          = try(each.value.values, [])
  type            = try(each.value.type, null)
  secure_type     = try(each.value.secure_type, null)
  description     = try(each.value.description, "Config parameter for ${local.ssm_naming_standard}/${split("_", each.key)[0]}/${upper(each.key)}")
  tier            = try(each.value.tier, null)
  key_id          = try(each.value.key_id, null)
  allowed_pattern = try(each.value.allowed_pattern, null)
  data_type       = try(each.value.data_type, null)
}

# Create Route53 zones
module "zones_main" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 2.10.2"

  zones = {
    "${local.route53_domain_name}" = {
      comment       = "Zone for ${local.route53_domain_name}"
      force_destroy = true
      tags          = local.route53_standard
    }
  }
  tags = merge(local.tags, local.route53_standard)
}

module "acm_main" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.3.2"

  domain_name = local.route53_domain_name
  zone_id     = module.zones_main.route53_zone_zone_id[local.route53_domain_name]

  subject_alternative_names = [
    "*.${var.env}.${local.route53_domain_name}",
  ]

  wait_for_validation = true

  tags = merge(local.tags, local.acm_standard, { Name = local.acm_naming_standard })
}

# Create AWS VPC architecture
module "vpc_main" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1.2"

  name                  = local.vpc_naming_standard
  cidr                  = local.vpc_cidr
  secondary_cidr_blocks = [local.rfc6598_cidr]
  azs                   = local.azs
  enable_ipv6           = true
  private_subnets = concat(
    [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 2, k)],
    [for k, v in local.azs : cidrsubnet(local.rfc6598_cidr, 3, k)]
  )
  database_subnets                                   = length(local.azs) <= 2 ? [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 16)] : [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 16)]
  elasticache_subnets                                = length(local.azs) <= 2 ? [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 18)] : [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 19)]
  redshift_subnets                                   = length(local.azs) <= 2 ? [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 20)] : [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 21)]
  intra_subnets                                      = length(local.azs) <= 2 ? [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 22)] : [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 23)]
  public_subnets                                     = length(local.azs) <= 2 ? [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 24)] : [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 25)]
  enable_nat_gateway                                 = true
  single_nat_gateway                                 = var.env == "dev" || var.env == "mstr" ? true : false
  one_nat_gateway_per_az                             = var.env == "dev" || var.env == "mstr" ? false : true
  private_subnet_ipv6_prefixes                       = length(local.azs) <= 2 ? [0, 1, 2, 3] : [0, 1, 2, 3, 4, 5]
  database_subnet_ipv6_prefixes                      = length(local.azs) <= 2 ? [4, 5] : [6, 7, 8]
  elasticache_subnet_ipv6_prefixes                   = length(local.azs) <= 2 ? [6, 7] : [9, 10, 11]
  redshift_subnet_ipv6_prefixes                      = length(local.azs) <= 2 ? [8, 9] : [12, 13, 14]
  intra_subnet_ipv6_prefixes                         = length(local.azs) <= 2 ? [10, 11] : [15, 16, 17]
  public_subnet_ipv6_prefixes                        = length(local.azs) <= 2 ? [12, 13] : [18, 19, 20]
  private_subnet_assign_ipv6_address_on_creation     = true
  database_subnet_assign_ipv6_address_on_creation    = true
  elasticache_subnet_assign_ipv6_address_on_creation = true
  redshift_subnet_assign_ipv6_address_on_creation    = true
  intra_subnet_assign_ipv6_address_on_creation       = true
  public_subnet_assign_ipv6_address_on_creation      = true
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
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = local.eks_naming_standard
  }
  tags = merge(local.tags, local.vpc_standard)
}

# Create IAM Role for service accounts (IRSA) for VPC CNI
module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30.0"

  role_name_prefix      = local.vpc_cni_naming_standard
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true
  vpc_cni_enable_ipv6   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks_main.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
  tags = local.tags
}

module "ebs_csi_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = local.vpc_cni_naming_standard
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks_main.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
  tags = local.tags
}

module "eks_main" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.16.0"
  vpc_id  = module.vpc_main.vpc_id
  # Only take non RFC 6598 private subnets
  control_plane_subnet_ids = module.vpc_main.intra_subnets
  subnet_ids               = slice(module.vpc_main.private_subnets, 0, length(local.azs))
  enable_irsa              = true
  create_kms_key           = false
  cluster_version          = "1.28"
  cluster_name             = local.eks_naming_standard
  cluster_encryption_config = {
    provider_key_arn = module.kms_main.key_arn
    resources        = ["secrets"]
  }
  cluster_endpoint_public_access = var.env == "dev" || var.env == "mstr" ? true : false
  cluster_ip_family              = "ipv4"
  create_cni_ipv6_iam_policy     = true
  create_cloudwatch_log_group    = false
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent              = true
      before_compute           = true
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
      configuration_values = jsonencode({
        eniConfig = {
          create = true,
          region = var.region,
          subnets = {
            "${local.azs[0]}" = {
              # Subnet ID for RFC 6598
              id             = module.vpc_main.private_subnets[2]
              securityGroups = [module.eks_main.cluster_primary_security_group_id, module.eks_main.cluster_security_group_id]
            },
            "${local.azs[1]}" = {
              # Subnet ID for RFC 6598
              id             = module.vpc_main.private_subnets[3]
              securityGroups = [module.eks_main.cluster_primary_security_group_id, module.eks_main.cluster_security_group_id]
            }
          }
        },
        env = {
          AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true",
          ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
      most_recent              = true
    }
  }
  node_security_group_tags = {
    "karpenter.sh/discovery" = local.eks_naming_standard
  }
  eks_managed_node_groups = {
    "ng-spot-general" = {
      # name                     = "${local.eks_naming_standard}-ng-spot-tool"
      # use_name_prefix          = false
      # iam_role_use_name_prefix = false
      # iam_role_name            = "${local.eks_naming_standard}-ng-spot-toolchain-role"
      # launch_template_name     = "${local.eks_naming_standard}-ng-spot-tool-lt"
      ami_id         = data.aws_ami.bottlerocket.image_id
      instance_types = ["t4g.medium"]
      platform       = "bottlerocket"
      # Use module user data template to bootstrap
      enable_bootstrap_user_data = true
      # This will get added to the template
      capacity_type = "SPOT"
      # Scaling config
      min_size             = 2
      max_size             = 2
      desired_size         = 2
      force_update_version = true
      bootstrap_extra_args = <<-EOT
        # The admin host container provides SSH access and runs with "superpowers".
        # It is disabled by default, but can be disabled explicitly.
        [settings.host-containers.admin]
        enabled = false

        # The control host container provides out-of-band access via SSM.
        # It is enabled by default, and can be disabled if you do not expect to use SSM.
        # This could leave you with no way to access the API and change settings on an existing node!
        [settings.host-containers.control]
        enabled = true

        # extra args added
        [settings.kernel]
        lockdown = "integrity"
      EOT
      update_config = {
        max_unavailable_percentage = 33 # or set `max_unavailable`
      }
      ebs_optimized           = true
      disable_api_termination = false
      enable_monitoring       = true
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            encrypted             = true
            kms_key_id            = module.kms_main.key_arn
            delete_on_termination = true
          }
        }
      }
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      username = "root"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/imam.arief.rhmn@gmail.com"
      username = "imam.arief.rhmn@gmail.com"
      groups   = ["system:masters"]
    },
  ]
  tags = merge(
    local.tags,
    local.eks_standard,
    {
      "karpenter.sh/discovery" = local.eks_naming_standard
    }
  )
}
