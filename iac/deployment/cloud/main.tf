# # Create General purpose KMS key
# module "kms_main" {
#   source                = "terraform-aws-modules/kms/aws"
#   version               = "~> 3.1.1"
#   aliases               = ["main/${local.kms_naming_standard}"]
#   description           = "${local.kms_naming_standard} cluster encryption key"
#   enable_default_policy = true
#   key_owners            = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/iac"]
#   key_users = [
#     "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/iac",
#     # "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github"
#   ]
#   key_service_roles_for_autoscaling = [
#     # required for the ASG to manage encrypted volumes for nodes
#     "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
#     # required for the cluster / persistentvolume-controller to create encrypted PVCs
#     # module.eks_main.cluster_iam_role_arn
#   ]
#   tags = merge(local.tags, local.kms_standard, { Name = local.kms_naming_standard })
# }

# # Create S3 bucket for terraform state
# module "bucket_tfstate" {
#   source                   = "terraform-aws-modules/s3-bucket/aws"
#   version                  = "~> 4.2.2"
#   bucket                   = local.s3_naming_standard
#   acl                      = "private"
#   force_destroy            = true
#   control_object_ownership = true
#   object_ownership         = "ObjectWriter"
#   attach_policy            = true
#   policy                   = data.aws_iam_policy_document.custom_bucket_policy.json
#   expected_bucket_owner    = data.aws_caller_identity.current.account_id
#   server_side_encryption_configuration = {
#     rule = {
#       apply_server_side_encryption_by_default = {
#         sse_algorithm     = "aws:kms"
#         kms_master_key_id = module.kms_main.key_arn
#       }
#     }
#   }
#   versioning = {
#     enabled = true
#   }

#   tags = merge(local.tags, local.s3_standard, { Name = local.s3_naming_standard })
# }

# # Create Route53 zones
# module "zones_main" {
#   source  = "terraform-aws-modules/route53/aws//modules/zones"
#   version = "~> 2.10.2"

#   zones = {
#     "${local.route53_domain_name}" = {
#       comment       = "Zone for ${local.route53_domain_name}"
#       force_destroy = true
#       tags          = local.route53_standard
#     }
#   }
#   tags = merge(local.tags, local.route53_standard)
# }

# # Create ACM certificate
# module "acm_main" {
#   source  = "terraform-aws-modules/acm/aws"
#   version = "~> 4.3.2"

#   domain_name = local.route53_domain_name
#   zone_id     = module.zones_main.route53_zone_zone_id[local.route53_domain_name]

#   subject_alternative_names = [
#     "*.${local.route53_domain_name}",
#   ]

#   wait_for_validation = true

#   tags = merge(local.tags, local.acm_standard, { Name = local.acm_naming_standard })
# }

# # ACM Module di us-east-1 used for Cognito custom domain 
# module "acm_main_virginia" {
#   source  = "terraform-aws-modules/acm/aws"
#   version = "~> 4.3.2"

#   providers = {
#     aws = aws.virginia
#   }

#   domain_name               = local.route53_domain_name
#   zone_id                   = module.zones_main.route53_zone_zone_id[local.route53_domain_name]
#   subject_alternative_names = ["*.${local.route53_domain_name}"]
#   wait_for_validation       = true

#   tags = merge(local.tags, local.acm_standard, { Name = local.acm_naming_standard })
# }

# # Create Secrets Manager
# module "secrets_iac" {
#   source  = "terraform-aws-modules/secrets-manager/aws"
#   version = "~> 1.3.1"

#   # Secret
#   name                    = local.secrets_manager_naming_standard
#   description             = "Secrets for ${local.secrets_manager_naming_standard}"
#   recovery_window_in_days = 0

#   # Policy
#   create_policy       = true
#   block_public_policy = true
#   policy_statements = {
#     admin = {
#       sid = "IacSecretAdmin"
#       principals = [
#         {
#           type        = "AWS"
#           identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
#         },
#         {
#           type        = "AWS"
#           identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
#         },
#         {
#           type        = "AWS"
#           identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/idanfreak@gmail.com"]
#         },
#         {
#           type        = "AWS"
#           identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/imam.arief.rhmn@gmail.com"]
#         },
#         {
#           type        = "AWS"
#           identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/iac"]
#         },
#       ]
#       actions   = ["secretsmanager:*"]
#       resources = ["*"]
#     }
#   }

#   # Version
#   ignore_secret_changes = true
#   secret_string = jsonencode({
#     argocd_ssh_base64      = base64encode(tls_private_key.argocd_ssh.private_key_pem)
#     argocd_github_secret   = random_password.argocd_github_secret.result
#     atlantis_github_secret = random_password.atlantis_github_secret.result
#     atlantis_password      = random_password.atlantis_password.result
#   })

#   tags = merge(local.tags, local.secrets_manager_standard)
# }

# # Create AWS VPC architecture
# module "vpc_main" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 5.16.0"

#   name                  = local.vpc_naming_standard
#   cidr                  = local.vpc_cidr
#   secondary_cidr_blocks = [local.rfc6598_cidr]
#   azs                   = local.azs
#   private_subnets = concat(
#     [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 2, k)],
#     [for k, v in local.azs : cidrsubnet(local.rfc6598_cidr, 3, k)]
#   )
#   database_subnets        = length(local.azs) <= 2 ? [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 16)] : [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 16)]
#   public_subnets          = length(local.azs) <= 2 ? [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 18)] : [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 5, k + 19)]
#   enable_nat_gateway      = true
#   single_nat_gateway      = var.env == "dev" ? true : false
#   one_nat_gateway_per_az  = var.env == "dev" ? false : true
#   map_public_ip_on_launch = true
#   private_subnet_names = concat(
#     [for k, v in local.azs : "${local.vpc_naming_standard}-node-${v}"],
#     # Custom network VPC CNI
#     [for k, v in local.azs : "${local.vpc_naming_standard}-app-${v}"]
#   )
#   public_subnet_tags = {
#     "kubernetes.io/role/elb" = 1
#   }

#   private_subnet_tags = {
#     "kubernetes.io/role/internal-elb" = 1
#     # Tags subnets for Karpenter auto-discovery
#     "karpenter.sh/discovery" = local.eks_naming_standard
#   }
#   tags = merge(local.tags, local.vpc_standard)
# }

# # Aurora
# module "aurora_main" {
#   source          = "terraform-aws-modules/rds-aurora/aws"
#   version         = "~> 9.10.0"
#   name            = local.aurora_naming_standard
#   engine          = "aurora-mysql"
#   engine_version  = "8.0"
#   master_username = "root"
#   instance_class  = var.env == "dev" ? "db.t4g.medium" : "db.r6g.large"
#   instances = {
#     one = {}
#   }
#   vpc_id               = module.vpc_main.vpc_id
#   db_subnet_group_name = module.vpc_main.database_subnet_group_name
#   security_group_rules = {
#     vpc_ingress = {
#       cidr_blocks = module.vpc_main.private_subnets_cidr_blocks // allow all private subnets (nodes and app subnets) to access the database
#     }
#   }
#   storage_encrypted                     = true
#   kms_key_id                            = module.kms_main.key_arn
#   manage_master_user_password           = true
#   iam_database_authentication_enabled   = true
#   autoscaling_enabled                   = true
#   autoscaling_min_capacity              = 1
#   autoscaling_max_capacity              = 5
#   apply_immediately                     = true
#   skip_final_snapshot                   = true
#   create_db_cluster_parameter_group     = false
#   create_db_parameter_group             = false
#   performance_insights_enabled          = true
#   performance_insights_kms_key_id       = module.kms_main.key_arn
#   performance_insights_retention_period = 7
#   publicly_accessible                   = false
#   enabled_cloudwatch_logs_exports       = ["audit", "error", "slowquery"]

#   tags = local.tags
# }


# module "eks_main" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 20.31.0"

#   vpc_id = module.vpc_main.vpc_id
#   # Only take non RFC 6598 private subnets
#   control_plane_subnet_ids  = module.vpc_main.intra_subnets
#   subnet_ids                = slice(module.vpc_main.private_subnets, 0, length(local.azs))
#   cluster_service_ipv4_cidr = local.service_cidr
#   enable_irsa               = true
#   create_kms_key            = false
#   cluster_version           = "1.31"
#   cluster_name              = local.eks_naming_standard
#   cluster_encryption_config = {
#     provider_key_arn = module.kms_main.key_arn
#     resources        = ["secrets"]
#   }
#   cluster_endpoint_public_access = var.env == "dev" ? true : false
#   cluster_ip_family              = "ipv4"
#   create_cloudwatch_log_group    = true
#   cluster_addons = {
#     eks-pod-identity-agent = {
#       before_compute = true // create the pod identity agent before the compute resources
#       most_recent    = true
#     }
#     vpc-cni = {
#       before_compute = true // create the vpc-cni before the compute resources
#       most_recent    = true
#       # service_account_role_arn = module.vpc_cni_irsa.iam_role_arn // for using irsa (deprecated) change to pod identity
#       configuration_values = jsonencode({
#         eniConfig = {
#           create = true,
#           region = var.region,
#           subnets = {
#             "${local.azs[0]}" = {
#               # Subnet ID for RFC 6598
#               id             = module.vpc_main.private_subnets[2]
#               securityGroups = [module.eks_main.cluster_primary_security_group_id, module.eks_main.cluster_security_group_id]
#             },
#             "${local.azs[1]}" = {
#               # Subnet ID for RFC 6598
#               id             = module.vpc_main.private_subnets[3]
#               securityGroups = [module.eks_main.cluster_primary_security_group_id, module.eks_main.cluster_security_group_id]
#             }
#           }
#         },
#         env = {
#           AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true",
#           ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
#           # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
#           ENABLE_PREFIX_DELEGATION = "true"
#           WARM_PREFIX_TARGET       = "1"
#         }
#       })
#     }
#     coredns = {
#       most_recent = true
#     }
#     kube-proxy = {
#       most_recent = true
#     }
#     aws-ebs-csi-driver = {
#       # service_account_role_arn = module.ebs_csi_irsa.iam_role_arn (deprecated)
#       most_recent = true
#     }

#     amazon-cloudwatch-observability = {
#       # service_account_role_arn = module.ebs_csi_irsa.iam_role_arn (deprecated)
#       most_recent = true
#     }
#   }
#   node_security_group_tags = {
#     "karpenter.sh/discovery" = local.eks_naming_standard
#   }

#   # Managed Node Groups for critical workloads, not for autoscaling
#   eks_managed_node_groups = {
#     "ng-ondemand-base" = {
#       ami_type                       = "BOTTLEROCKET_x86_64"
#       use_latest_ami_release_version = true
#       instance_types                 = var.env == "dev" ? ["t3.medium"] : ["m6i.large"]
#       enable_bootstrap_user_data     = true
#       capacity_type                  = var.env == "dev" ? "SPOT" : "ON_DEMAND"
#       min_size                       = 2
#       max_size                       = 2
#       desired_size                   = 2
#       force_update_version           = true
#       bootstrap_extra_args           = <<-EOT
#         # The admin host container provides SSH access and runs with "superpowers".
#         # It is disabled by default, but can be disabled explicitly.
#         [settings.host-containers.admin]
#         enabled = false

#         # The control host container provides out-of-band access via SSM.
#         # It is enabled by default, and can be disabled if you do not expect to use SSM.
#         # This could leave you with no way to access the API and change settings on an existing node!
#         [settings.host-containers.control]
#         enabled = true

#         # extra args added
#         [settings.kernel]
#         lockdown = "integrity"
#       EOT
#       # update_config = {
#       #   max_unavailable_percentage = 1 # or set `max_unavailable`
#       # }
#       ebs_optimized           = true
#       disable_api_termination = false
#       enable_monitoring       = true
#       block_device_mappings = {
#         xvda = {
#           device_name = "/dev/xvda"
#           ebs = {
#             volume_size           = 20
#             volume_type           = "gp3"
#             iops                  = 3000
#             throughput            = 150
#             encrypted             = true
#             kms_key_id            = module.kms_main.key_arn
#             delete_on_termination = true
#           }
#         }
#       }
#     }
#   }

#   # aws-auth configmap (deprecated use access_entries instead)
#   # manage_aws_auth_configmap = true
#   # aws_auth_users = [
#   #   {
#   #     userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#   #     username = "root"
#   #     groups   = ["system:masters"]
#   #   },
#   #   {
#   #     userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/imam.arief.rhmn@gmail.com"
#   #     username = "imam.arief.rhmn@gmail.com"
#   #     groups   = ["system:masters"]
#   #   },
#   # ]

#   # Cluster access entry
#   # To add the current caller identity as an administrator
#   enable_cluster_creator_admin_permissions = false

#   access_entries = {
#     # One access entry with a policy associated
#     iac = {
#       principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/iac"
#       policy_associations = {
#         iac = {
#           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#           access_scope = {
#             type = "cluster"
#           }
#         }
#       }
#     }
#     atlantis = {
#       principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/atlantis-role"
#       policy_associations = {
#         atlantis = {
#           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#           access_scope = {
#             type = "cluster"
#           }
#         }
#       }
#     }
#     admin = {
#       principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/imam.arief.rhmn@gmail.com"
#       policy_associations = {
#         iac = {
#           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#           access_scope = {
#             type = "cluster"
#           }
#         }
#       }
#     }
#     # root = {
#     #   principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#     #   policy_associations = {
#     #     iac = {
#     #       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#     #       access_scope = {
#     #         type = "cluster"
#     #       }
#     #     }
#     #   }
#     # }
#   }

#   tags = merge(
#     local.tags,
#     local.eks_standard,
#     {
#       "karpenter.sh/discovery" = local.eks_naming_standard
#     }
#   )
# }

# # Create IAM Role for service accounts (IRSA) for VPC CNI
# module "vpc_cni_irsa" {
#   source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

#   role_name_prefix      = "aws-vpc-cni-ipv4-irsa"
#   attach_vpc_cni_policy = true
#   vpc_cni_enable_ipv4   = true

#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks_main.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:aws-node"]
#     }
#   }
#   tags = local.tags
# }

# module "ebs_csi_irsa" {
#   source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

#   role_name             = "aws-ebs-csi-irsa"
#   attach_ebs_csi_policy = true

#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks_main.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
#     }
#   }
#   tags = local.tags
# }

# # EKS Pod Identity for VPC CNI
# module "aws_vpc_cni_ipv4_pod_identity" {
#   source  = "terraform-aws-modules/eks-pod-identity/aws"
#   version = "~> 1.7.0"

#   name = "aws-vpc-cni-ipv4"

#   attach_aws_vpc_cni_policy = true
#   aws_vpc_cni_enable_ipv4   = true

#   association_defaults = {
#     namespace       = "kube-system"
#     service_account = "aws-node"
#   }

#   # Cluster Association
#   associations = {
#     main = {
#       cluster_name = module.eks_main.cluster_name
#     }
#   }
#   tags = local.tags
# }

# # EKS Pod Identity for AWS EBS CSI
# module "aws_ebs_csi_pod_identity" {
#   source  = "terraform-aws-modules/eks-pod-identity/aws"
#   version = "~> 1.7.0"

#   name = "aws-ebs-csi"

#   attach_aws_ebs_csi_policy = true
#   aws_ebs_csi_kms_arns      = [module.kms_main.key_arn]
#   # Pod Identity Associations
#   association_defaults = {
#     namespace       = "kube-system"
#     service_account = "ebs-csi-controller-sa"
#   }
#   # Cluster Association
#   associations = {
#     main = {
#       cluster_name = module.eks_main.cluster_name
#     }
#   }

#   tags = local.tags
# }

# # Create Storage Class for gp3
# resource "kubernetes_storage_class_v1" "gp3" {
#   metadata {
#     name = "gp3"
#     annotations = {
#       "storageclass.kubernetes.io/is-default-class" = "true"
#     }
#   }
#   storage_provisioner = "ebs.csi.aws.com"
#   reclaim_policy      = "Delete"
#   parameters = {
#     type       = "gp3"
#     iops       = "3000"
#     throughput = "125"
#   }
#   volume_binding_mode = "WaitForFirstConsumer"
# }

# module "aws_cloudwatch_observability_pod_identity" {
#   source  = "terraform-aws-modules/eks-pod-identity/aws"
#   version = "~> 1.7.0"

#   name = "aws-cloudwatch-observability"

#   attach_aws_cloudwatch_observability_policy = true

#   # Pod Identity Associations
#   association_defaults = {
#     namespace       = "amazon-cloudwatch"
#     service_account = "cloudwatch-agent"
#   }

#   associations = {
#     main = {
#       cluster_name = module.eks_main.cluster_name
#     }
#   }

#   tags = {
#     Environment = "dev"
#   }
# }

# # ArgoCD
# # ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes.
# module "argocd" {
#   source = "../../modules/helm"

#   region           = var.region
#   standard         = local.argocd_standard
#   repository       = "https://argoproj.github.io/argo-helm"
#   chart            = "argo-cd"
#   values           = ["${file("manifest/${local.argocd_standard.Feature}.yaml")}"]
#   namespace        = "argocd"
#   create_namespace = true
#   dns_name         = local.route53_domain_name
#   extra_vars = {
#     github_orgs      = var.github_orgs
#     github_client_id = var.github_oauth_client_id
#     ARGOCD_VERSION   = var.argocd_version
#     AVP_VERSION      = var.argocd_vault_plugin_version
#     server_insecure  = true

#     # ref https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd
#     # ingress
#     ingress_enabled    = true
#     ingress_controller = "aws"
#     ingress_class_name = "alb"
#     # ingress alb
#     alb_certificate_arn              = module.acm_main.acm_certificate_arn
#     alb_ssl_policy                   = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#     alb_backend_protocol             = "HTTP"
#     alb_listen_ports                 = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
#     alb_scheme                       = "internet-facing"
#     alb_target_type                  = "ip"
#     alb_group_name                   = "${var.unit}-${var.env}-${local.argocd_standard.Code}-ingress"
#     alb_group_order                  = "1"
#     alb_healthcheck_path             = "/"
#     alb_ssl_redirect                 = 443
#     aws_alb_service_type             = "ClusterIP"
#     aws_alb_backend_protocol_version = "GRPC"
#   }
#   helm_sets_sensitive = [
#     {
#       name  = "configs.secret.githubSecret"
#       value = random_password.argocd_github_secret.result
#     },
#     {
#       name  = "configs.secret.extra.dex\\.github\\.clientSecret"
#       value = jsondecode(data.aws_secretsmanager_secret_version.secret_iac_current.secret_string)["github_oauth_client_secret"]
#     },
#   ]
#   depends_on = [
#     module.eks_main,
#   ]
# }

# # ArgoCD Vault Plugin (AVP) Pod Identity
# module "avp_custom_pod_identity" {
#   source  = "terraform-aws-modules/eks-pod-identity/aws"
#   version = "~> 1.7.0"

#   name            = "avp_role"
#   use_name_prefix = false

#   # ArgoCD Vault Plugin (AVP) is installed in the argocd-repo-server 
#   # So we need to attach the policy to the argocd-repo-server service account
#   association_defaults = {
#     namespace       = "argocd"
#     service_account = "argocd-repo-server"
#     tags            = { App = "avp" }
#   }

#   associations = {
#     main = {
#       cluster_name = module.eks_main.cluster_name
#     }
#   }

#   attach_custom_policy    = true
#   source_policy_documents = [data.aws_iam_policy_document.avp_policy.json]

#   tags = local.tags
# }

# # Atlantis
# module "atlantis" {
#   source = "../../modules/helm"

#   region           = var.region
#   standard         = local.atlantis_standard
#   repository       = "https://runatlantis.github.io/helm-charts"
#   chart            = "atlantis"
#   values           = ["${file("manifest/${local.atlantis_standard.Feature}.yaml")}"]
#   namespace        = "atlantis"
#   create_namespace = true
#   dns_name         = local.route53_domain_name
#   extra_vars = {
#     github_user = var.github_owner

#     # ingress
#     ingress_enabled    = true
#     ingress_class_name = "alb"
#     # ingress alb
#     alb_certificate_arn              = module.acm_main.acm_certificate_arn
#     alb_ssl_policy                   = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#     alb_backend_protocol             = "HTTP"
#     alb_listen_ports                 = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
#     alb_scheme                       = "internet-facing"
#     alb_target_type                  = "ip"
#     alb_group_name                   = "${var.unit}-${var.env}-${local.atlantis_standard.Code}-ingress"
#     alb_group_order                  = "2"
#     alb_healthcheck_path             = "/"
#     alb_ssl_redirect                 = 443
#     aws_alb_service_type             = "ClusterIP"
#     aws_alb_backend_protocol_version = "GRPC"
#   }
#   helm_sets_sensitive = [
#     {
#       name  = "github.token"
#       value = jsondecode(data.aws_secretsmanager_secret_version.secret_iac_current.secret_string)["github_token"]
#     },
#     {
#       name  = "github.secret"
#       value = random_password.atlantis_github_secret.result
#     },
#   ]
#   depends_on = [
#     module.eks_main,
#   ]
# }

# module "atlantis_custom_pod_identity" {
#   source  = "terraform-aws-modules/eks-pod-identity/aws"
#   version = "~> 1.7.0"

#   name            = "${local.atlantis_standard.Feature}-role"
#   use_name_prefix = false

#   # ArgoCD Vault Plugin (AVP) is installed in the argocd-repo-server 
#   # So we need to attach the policy to the argocd-repo-server service account
#   association_defaults = {
#     namespace       = local.atlantis_standard.Feature
#     service_account = "${local.atlantis_standard.Feature}-sa"
#     tags            = { App = local.atlantis_standard.Feature }
#   }

#   associations = {
#     main = {
#       cluster_name = module.eks_main.cluster_name
#     }
#   }

#   attach_custom_policy    = true
#   source_policy_documents = [data.aws_iam_policy_document.atlantis_policy.json]

#   tags = local.tags
# }

# # Setup repository for argocd and atlantis
# module "repo_phl" {
#   source    = "../../modules/github"
#   repo_name = var.github_repo
#   owner     = var.github_owner
#   webhooks = {
#     argocd = {
#       configuration = {
#         url          = "https://argocd.phl.blast.co.id/api/webhook"
#         content_type = "json"
#         insecure_ssl = false
#         secret       = random_password.argocd_github_secret.result
#       }
#       active = true
#       events = ["push"]
#     }
#     atlantis = {
#       configuration = {
#         url          = "https://atlantis.phl.blast.co.id/events"
#         content_type = "json"
#         insecure_ssl = false
#         secret       = random_password.atlantis_github_secret.result
#       }
#       active = true
#       events = ["push", "pull_request", "pull_request_review", "issue_comment"]
#     }
#   }
#   create_deploy_key          = true
#   add_repo_ssh_key_to_argocd = true
#   public_key                 = tls_private_key.argocd_ssh.public_key_openssh
#   ssh_key                    = tls_private_key.argocd_ssh.private_key_pem
#   is_deploy_key_read_only    = false
#   argocd_namespace           = "argocd"
#   depends_on = [
#     module.argocd,
#     module.atlantis,
#   ]
# }

# # Create OIDC provider for GitHub Actions
# module "oidc_github" {
#   source  = "unfunco/oidc-github/aws"
#   version = "1.8.0"

#   attach_read_only_policy = false
#   additional_thumbprints  = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
#   # Policy to push image to ECR and upload test report to S3
#   iam_role_policy_arns    = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/phl-dev-svc-products"]

#   github_repositories = [
#     "greyhats13/phl-store",
#   ]
# }

# # Karpenter
# # resource "helm_release" "karpenter" {
# #   namespace           = "kube-system"
# #   name                = "karpenter"
# #   repository          = "oci://public.ecr.aws/karpenter"
# #   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
# #   repository_password = data.aws_ecrpublic_authorization_token.token.password
# #   chart               = "karpenter"
# #   version             = "1.1.0"
# #   wait                = false

# #   values = [
# #     <<-EOT
# #     dnsPolicy: Default
# #     settings:
# #       clusterName: ${module.eks_main.cluster_name}
# #       clusterEndpoint: ${module.eks_main.cluster_endpoint}
# #       interruptionQueue: ${module.karpenter.queue_name}
# #     webhook:
# #       enabled: false
# #     EOT
# #   ]
# # }

# # resource "kubectl_manifest" "karpenter_node_class" {
# #   yaml_body = <<-YAML
# #     apiVersion: karpenter.k8s.aws/v1beta1
# #     kind: EC2NodeClass
# #     metadata:
# #       name: autoscaling
# #     spec:
# #       amiFamily: Bottlerocket
# #       role: ${module.karpenter.node_iam_role_name}
# #       subnetSelectorTerms:
# #         - tags:
# #             karpenter.sh/discovery: ${module.eks_main.cluster_name}
# #       securityGroupSelectorTerms:
# #         - tags:
# #             karpenter.sh/discovery: ${module.eks_main.cluster_name}
# #       tags:
# #         karpenter.sh/discovery: ${module.eks_main.cluster_name}
# #   YAML

# #   depends_on = [
# #     helm_release.karpenter
# #   ]
# # }

# # resource "kubectl_manifest" "karpenter_node_pool" {
# #   yaml_body = <<-YAML
# #     apiVersion: karpenter.sh/v1beta1
# #     kind: NodePool
# #     metadata:
# #       name: default
# #     spec:
# #       template:
# #         spec:
# #           nodeClassRef:
# #             name: default
# #           requirements:
# #             - key: "karpenter.k8s.aws/instance-category"
# #               operator: In
# #               values: ["t","c", "m", "r"]
# #             - key: "karpenter.k8s.aws/instance-cpu"
# #               operator: In
# #               values: ["2", "4", "8", "16"]
# #             - key: "karpenter.k8s.aws/instance-hypervisor"
# #               operator: In
# #               values: ["nitro"]
# #             - key: "karpenter.k8s.aws/instance-generation"
# #               operator: Gt
# #               values: ["5"]
# #       limits:
# #         cpu: 1000
# #       disruption:
# #         consolidationPolicy: WhenEmpty
# #         consolidateAfter: 30s
# #   YAML

# #   depends_on = [
# #     kubectl_manifest.karpenter_node_class
# #   ]
# # }

# # # AWS required resources for Karpenter
# # module "eks_karpenter" {
# #   source  = "terraform-aws-modules/eks/aws//modules/karpenter"
# #   version = "~> 20.31.0"

# #   cluster_name = module.eks_main.cluster_name

# #   enable_v1_permissions = true

# #   enable_pod_identity             = true
# #   create_pod_identity_association = true

# #   # Used to attach additional IAM policies to the Karpenter node IAM role
# #   node_iam_role_additional_policies = {
# #     AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# #   }

# #   tags = local.tags
# # }

# module "cognito_pool" {
#   source                       = "../../modules/cognito"
#   region                       = var.region
#   name                         = local.cognito_naming_standard
#   supported_identity_providers = ["COGNITO"]
#   domain                       = "oauth.${local.route53_domain_name}"
#   certificate_arn              = module.acm_main_virginia.acm_certificate_arn
#   zone_id                      = module.zones_main.route53_zone_zone_id[local.route53_domain_name]
#   alb_dns                      = data.aws_lb.alb.dns_name
#   alb_zone_id                  = data.aws_lb.alb.zone_id
#   explicit_auth_flows = [
#     "ALLOW_USER_PASSWORD_AUTH",
#     "ALLOW_USER_SRP_AUTH",
#     "ALLOW_REFRESH_TOKEN_AUTH"
#   ]
#   password_policy = {
#     minimum_length    = 8
#     require_lowercase = true
#     require_numbers   = true
#     require_symbols   = true
#     require_uppercase = true
#   }
#   allowed_oauth_flows_user_pool_client = true
#   generate_secret                      = true
#   resource_servers = {
#     "apigw" = {
#       identifier = "https://api.${local.route53_domain_name}"
#       name       = "${local.cognito_naming_standard}-apigw"
#       scopes = [
#         {
#           scope_name        = "all"
#           scope_description = "Get access to all API Gateway endpoints."
#         }
#       ]
#     }
#   }
#   allowed_oauth_flows      = ["client_credentials"]
#   auto_verified_attributes = ["email"]
#   username_attributes      = ["email"]
#   access_token_validity    = 60
#   id_token_validity        = 60
#   refresh_token_validity   = 30
#   tags                     = local.cognito_standard
# }

# module "api_sg" {
#   source  = "terraform-aws-modules/security-group/aws"
#   version = "~> 5.2.0"

#   name        = "${local.api_naming_standard}-sg"
#   description = "API Gateway security group fort ${local.api_naming_standard}"
#   vpc_id      = module.vpc_main.vpc_id

#   ingress_cidr_blocks = ["0.0.0.0/0"]
#   ingress_rules       = ["http-80-tcp", "https-443-tcp"]

#   egress_rules = ["all-all"]

#   tags = local.api_standard
# }


# module "api" {
#   source  = "terraform-aws-modules/apigateway-v2/aws"
#   version = "~> 5.2.1"

#   name          = local.api_naming_standard
#   description   = "API Gateway for ${local.api_naming_standard}"
#   protocol_type = "HTTP"
#   # body = templatefile("manifest/openapi.yaml", {
#   #   vpc_link_id      = module.api.vpc_links["vpc-main"]["id"],
#   #   alb_listener_arn = data.aws_lb_listener.listener.arn,
#   # })

#   cors_configuration = {
#     allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
#     allow_methods = ["*"]
#     allow_origins = ["*"]
#   }

#   # Custom domain
#   create_domain_name             = true
#   hosted_zone_name               = module.zones_main.route53_zone_name[local.route53_domain_name]
#   domain_name                    = "api.${local.route53_domain_name}"
#   create_certificate             = false
#   domain_name_certificate_arn    = module.acm_main.acm_certificate_arn
#   create_stage                   = true
#   deploy_stage                   = false
#   create_routes_and_integrations = false
#   stage_access_log_settings = {
#     create_log_group            = true
#     log_group_retention_in_days = 7
#     format = jsonencode({
#       context = {
#         domainName              = "$context.domainName"
#         integrationErrorMessage = "$context.integrationErrorMessage"
#         protocol                = "$context.protocol"
#         requestId               = "$context.requestId"
#         requestTime             = "$context.requestTime"
#         responseLength          = "$context.responseLength"
#         routeKey                = "$context.routeKey"
#         stage                   = "$context.stage"
#         status                  = "$context.status"
#         error = {
#           message      = "$context.error.message"
#           responseType = "$context.error.responseType"
#         }
#         identity = {
#           sourceIP = "$context.identity.sourceIp"
#         }
#         integration = {
#           error             = "$context.integration.error"
#           integrationStatus = "$context.integration.integrationStatus"
#         }
#       }
#     })
#   }

#   authorizers = {
#     cognito = {
#       authorizer_type  = "JWT"
#       name             = "cognito-authorizer"
#       identity_sources = ["$request.header.Authorization"]
#       jwt_configuration = {
#         issuer   = "https://${module.cognito_pool.cognito_user_pool_endpoint}"
#         audience = [module.cognito_pool.cognito_user_pool_client_id]
#       }
#     }
#   }

#   stage_default_route_settings = {
#     detailed_metrics_enabled = true
#     throttling_burst_limit   = 100
#     throttling_rate_limit    = 100
#   }

#   # VPC Link
#   vpc_links = {
#     vpc-main = {
#       name               = "${local.api_naming_standard}-vpc-link"
#       security_group_ids = [module.api_sg.security_group_id]
#       subnet_ids         = module.vpc_main.public_subnets
#     }
#   }

#   tags = {
#     Environment = "dev"
#     Terraform   = "true"
#   }
# }
