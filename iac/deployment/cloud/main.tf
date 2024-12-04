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
    module.eks_main.cluster_iam_role_arn
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
  version = "~> 5.16.0"

  name                  = local.vpc_naming_standard
  cidr                  = local.vpc_cidr
  secondary_cidr_blocks = [local.rfc6598_cidr]
  azs                   = local.azs
  private_subnets = concat(
    [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 2, k)],
    [for k, v in local.azs : cidrsubnet(local.rfc6598_cidr, 3, k)]
  )
  database_subnets        = length(local.azs) <= 2 ? [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 16)] : [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 16)]
  public_subnets          = length(local.azs) <= 2 ? [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 18)] : [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 19)]
  enable_nat_gateway      = true
  single_nat_gateway      = var.env == "dev" ? true : false
  one_nat_gateway_per_az  = var.env == "dev" ? false : true
  map_public_ip_on_launch = true
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
    "karpenter.sh/discovery" = local.eks_naming_standard
  }
  tags = merge(local.tags, local.vpc_standard)
}

module "eks_main" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.30.1"
  vpc_id  = module.vpc_main.vpc_id
  # Only take non RFC 6598 private subnets
  control_plane_subnet_ids = module.vpc_main.intra_subnets
  subnet_ids               = slice(module.vpc_main.private_subnets, 0, length(local.azs))
  enable_irsa              = true
  create_kms_key           = false
  cluster_version          = "1.31"
  cluster_name             = local.eks_naming_standard
  cluster_encryption_config = {
    provider_key_arn = module.kms_main.key_arn
    resources        = ["secrets"]
  }
  cluster_endpoint_public_access = var.env == "dev" ? true : false
  cluster_ip_family              = "ipv4"
  create_cni_ipv6_iam_policy     = true
  create_cloudwatch_log_group    = true
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
      # service_account_role_arn = module.vpc_cni_irsa.iam_role_arn (deprecated)
      service_account_role_arn = module.aws_vpc_cni_ipv4_pod_identity.iam_role_arn
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
      # service_account_role_arn = module.ebs_csi_irsa.iam_role_arn (deprecated)
      service_account_role_arn = module.aws_ebs_csi_pod_identity.iam_role_arn
      most_recent              = true
    }
  }
  node_security_group_tags = {
    "karpenter.sh/discovery" = local.eks_naming_standard
  }

  # Managed Node Groups for critical workloads, not for autoscaling
  eks_managed_node_groups = {
    "ng-ondemand-base" = {
      ami_type                       = "BOTTLEROCKET_x86_64"
      use_latest_ami_release_version = true
      instance_types                 = ["m5a.large"]
      enable_bootstrap_user_data     = true
      capacity_type                  = "ON_DEMAND"
      min_size                       = 2
      max_size                       = 2
      desired_size                   = 2
      force_update_version           = true
      bootstrap_extra_args           = <<-EOT
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
  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    # One access entry with a policy associated
    iac = {
      principal_arn = "arn:aws:iam::123456789012:role/iac"
      policy_associations = {
        iac = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    root = {
      principal_arn = "arn:aws:iam::123456789012:user:root"
      policy_associations = {
        iac = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # aws-auth configmap (deprecated)
  # manage_aws_auth_configmap = true
  # aws_auth_users = [
  #   {
  #     userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  #     username = "root"
  #     groups   = ["system:masters"]
  #   },
  #   {
  #     userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/imam.arief.rhmn@gmail.com"
  #     username = "imam.arief.rhmn@gmail.com"
  #     groups   = ["system:masters"]
  #   },
  # ]
  tags = merge(
    local.tags,
    local.eks_standard,
    {
      "karpenter.sh/discovery" = local.eks_naming_standard
    }
  )
}

# Create IAM Role for service accounts (IRSA) for VPC CNI (deprecated, use AWS EKS Pod Identity instead)
module "vpc_cni_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name_prefix      = local.vpc_cni_naming_standard
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

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

# EKS Pod Identity for VPC CNI
module "aws_vpc_cni_ipv4_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "aws-vpc-cni-ipv4"

  attach_aws_vpc_cni_policy = true
  aws_vpc_cni_enable_ipv4   = true

  association_defaults = {
    namespace       = "kube-system"
    service_account = "aws-node"
  }

  # Cluster Association
  associations = {
    main = {
      cluster_name = module.eks_main.cluster_name
    }
  }

  tags = local.tags
}

# EKS Pod Identity for AWS EBS CSI
module "aws_ebs_csi_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "aws-ebs-csi"

  attach_aws_ebs_csi_policy = true
  aws_ebs_csi_kms_arns      = [module.kms_main.key_arn]
  # Pod Identity Associations
  association_defaults = {
    namespace       = "kube-system"
    service_account = "ebs-csi-controller-sa"
  }
  # Cluster Association
  associations = {
    main = {
      cluster_name = module.eks_main.cluster_name
    }
  }

  tags = local.tags
}

module "aws_cloudwatch_observability_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "aws-cloudwatch-observability"

  attach_aws_cloudwatch_observability_policy = true

  # Pod Identity Associations
  association_defaults = {
    namespace       = "amazon-cloudwatch"
    service_account = "cloudwatch-agent"
  }

  associations = {
    main = {
      cluster_name = module.eks_main.cluster_name
    }
  }

  tags = {
    Environment = "dev"
  }
}

# AWS required resources for Karpenter
module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = module.eks_main.cluster_name

  enable_v1_permissions = true

  enable_pod_identity             = true
  create_pod_identity_association = true

  # Used to attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags
}