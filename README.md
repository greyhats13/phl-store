# Instructions
Starting from an AWS empty environment, setup a Kubernetes cluster and Aurora MySQL cluster including all the necessary resources
using Terraform.
Next deploy a sample application phl-store to the Kubernetes Cluster (preferably with Helm). It is a simple CRUD application and should
be accessible from the outside world. The docker image URL can be found at https://hub.docker.com/r/zylwin/phl-store . The app uses
MySQL as the database to store and retrieve data. The config file is mounted as /config/config.json . The docker-compose file is
attached below for your reference.
For the application deployment, use any CI/CD tools of your choice.

# Submission
For your submission, create a private Github repository and include the following
1. Architectural diagram to explain your architecture.
2. The relevant configuration scripts (eg: Terraform).
3. In the README, include
a. Instruction on how to setup/run the infrastructure and deploy the app
b. Include high level steps on how would you manage the secrets and configuration changes
c. Also include high level steps to make this infrastructure more secure, automate and reliable

# AWS Infrastructure Design

<p align="center">
  <img src="img/aws.png" alt="aws">
</p>

## VPC

The VPC in this setup is designed to be the backbone of our AWS infrastructure. It provides isolated networking for all resources, ensuring efficient communication while maintaining strict security boundaries. The CIDR block for the VPC is 10.0.0.0/16, giving us a large pool of IP addresses to allocate across subnets for different use cases.

I’ve also added a secondary CIDR block, 100.64.0.0/16, which follows the RFC6598 standard. This block is specifically reserved for Kubernetes pods in EKS, making sure that pod IP addresses don’t conflict with node IPs or on-premise network configurations. By separating pod IPs into their own CIDR block, I avoid running out of IPs in the primary VPC range even as the cluster scales.

### Subnet Design

The VPC has three types of subnets: public, private, and database subnets. These subnets are distributed across multiple Availability Zones (AZs) for fault tolerance.
- Public Subnets are where internet-facing resources live, like NAT Gateways and Application Load Balancers (ALBs). These are also used for bastion hosts when you need secure administrative access to private resources. Public subnets have public IPs and are configured with proper routing to handle incoming and outgoing internet traffic. The ALBs distribute traffic to internal workloads, and the NAT Gateways allow private subnets to securely access external resources without exposing themselves.
- Private Subnets are used for critical internal resources like Kubernetes worker nodes (EKS nodes) and application pods. These subnets don’t have direct internet access. Instead, all outbound traffic from these subnets goes through the NAT Gateways. Kubernetes workloads are dynamically scaled within these subnets, thanks to tagging for auto-discovery. Tags like kubernetes.io/role/internal-elb help Kubernetes know which subnets to use for internal load balancers, while tags like karpenter.sh/discovery let Karpenter manage autoscaling based on workload demands.
- Database Subnets are isolated further, used only for our Aurora database instances. They are designed to keep the database secure and separate from application traffic, with strict access controls.

### NAT Gateways

I’ve deployed NAT Gateways in public subnets to handle outbound internet traffic from private resources. For the development environment, I personally an use a single NAT Gateway to optimize costs. In production, each AZ has its own NAT Gateway for high availability. This setup ensures that even if one AZ or NAT Gateway fails, resources in other AZs can still access the internet.

NAT Gateways are crucial for security because they allow private resources to access external services (like downloading updates) without exposing themselves directly to the internet. Plus, they scale automatically to handle more traffic as needed, which makes them a perfect fit for a scalable architecture.

### Scalability and Availability

The VPC is designed to support growth and handle failures gracefully. By spreading subnets across multiple AZs, we ensure that workloads remain available even if one AZ goes down. For Kubernetes, the RFC6598 secondary CIDR block provides a huge IP range dedicated to pods, so scaling up workloads will never run into IP address exhaustion issues. Additionally, resources like NAT Gateways, ALBs, and EKS nodes are designed to scale automatically, ensuring the system can handle sudden traffic spikes.

### Security

Security is baked into every layer of this design. Private subnets ensure that critical resources are not directly exposed to the internet. Security groups and network ACLs enforce strict traffic controls, only allowing necessary communication between resources. Database subnets are completely isolated, with access restricted to specific application workloads.

The encryption is handled using AWS KMS for sensitive data, and the ALBs use SSL certificates from AWS ACM for secure communication. This way, data is always protected whether it’s at rest or in transit.

This VPC setup is a solid foundation for our infrastructure. It’s scalable, secure, and built to handle failures without downtime. By following AWS best practices and using tools like Terraform, I’ve ensured that the network is robust and future-proof.

### VPC: Talking is Cheap, Show Me the Code
Path: iac/deployment/cloud/main.tf
```hcl
 # VPC Locals
  vpc_cidr     = "10.0.0.0/16"
  rfc6598_cidr = "100.64.0.0/16"
  service_cidr = "10.1.0.0/16"
  azs          = slice(data.aws_availability_zones.available.names, 0, length(data.aws_availability_zones.available.names))
  vpc_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "vpc"
    Feature = "main"
  }
  vpc_naming_standard = "${local.vpc_standard.Unit}-${local.vpc_standard.Env}-${local.vpc_standard.Code}-${local.vpc_standard.Feature}"

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
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = local.eks_naming_standard
  }
  tags = merge(local.tags, local.vpc_standard)
}
```

## Elastic Kubernetes Service (EKS)
The EKS setup in this design is built for running containerized workloads efficiently. It takes advantage of AWS-native tools and Kubernetes features to ensure high performance, availability, and robust security. By using modules, we’ve automated many configurations, such as creating all required security groups for the control plane, nodes, and other components.

### EKS Cluster Configuration

The EKS cluster runs Kubernetes version 1.31 and is designed to operate in a private networking setup. The control plane spans multiple AZs, ensuring high availability. All communication between the control plane and worker nodes is encrypted for security.

The VPC’s subnets are configured to support the cluster’s needs:
- The control plane uses private subnets for communication, ensuring that it is isolated from public exposure.
- Worker nodes and pods run in private subnets to minimize exposure while allowing managed traffic routing through NAT Gateways and ALBs.

### Why BottleRocket?

The worker nodes in the managed node group use BottleRocket as the AMI. This is a lightweight, purpose-built OS for containerized workloads, and it comes with several advantages:
-	Performance: Since it’s stripped down to just the essentials for running containers, it boots faster and uses fewer resources compared to general-purpose OSes.
- Security: BottleRocket minimizes the attack surface by removing unnecessary packages and includes built-in hardening features like kernel lockdown. It integrates seamlessly with AWS services like SSM for secure management.

### Node Groups and Autoscaling

The cluster has a managed node group for critical workloads that require high reliability. These nodes:
- Run on On-Demand instances to ensure stability during normal traffic conditions.
- Have a fixed size (2 nodes) to avoid disruption from frequent scaling events.

For handling dynamic workloads, the cluster relies on Karpenter. Karpenter automatically provisions nodes based on demand, offering rapid scaling and cost efficiency. This separation of critical and dynamic workloads ensures stability while maintaining flexibility.

### Storage and Volume Management

The setup includes EBS CSI (Container Storage Interface) for Kubernetes, which allows the cluster to provision storage dynamically. We’ve configured gp3 volumes as the default storage class. The benefits of gp3 are:
- Higher performance: With up to 3,000 IOPS and 125 MiB/s throughput, gp3 volumes provide consistent performance.
- Cost efficiency: gp3 is cheaper than gp2 for equivalent performance.
- Encryption: All volumes are encrypted using AWS KMS secure data at rest.

### Networking with VPC CNI

The cluster uses the AWS VPC CNI plugin to manage pod networking. It’s configured to use the secondary CIDR block (RFC6598, 100.64.0.0/16) to ensure there are enough IPs for pods, even in large-scale deployments. This separation also avoids conflicts with the primary CIDR and simplifies integration with on-prem networks.

The VPC CNI plugin is enhanced with:
- Prefix delegation: This increases the number of available IPs per ENI, reducing the risk of IP exhaustion.
- Custom ENI configuration: Subnets and security groups are explicitly defined, providing fine-grained control over network access.

Add-ons for Observability and Scalability

Several add-ons are installed to enhance the functionality and observability of the cluster:
- CloudWatch Observability: Provides centralized monitoring and logging for Kubernetes workloads. This simplifies debugging and ensures better visibility into the system performance.
- CoreDNS: Handles service discovery within the cluster.
- Kube-proxy: Manages network proxying for Kubernetes services.

### IAM Integration with Pod Identity

For managing permissions, the cluster uses EKS Pod Identity instead of the traditional IAM Roles for Service Accounts (IRSA). Pod Identity provides:
- Granular permissions: Pods can assume roles with minimal required permissions, enhancing security.
- Simpler configuration: It reduces the need for managing trust relationships manually.

### EKS: Talking is Cheap, Show Me the Code
Path: iac/deployment/cloud/main.tf
```hcl
eks_standard = {
  Unit    = var.unit
  Env     = var.env
  Code    = "eks"
  Feature = "main"
}
eks_naming_standard = "${local.eks_standard.Unit}-${local.eks_standard.Env}-${local.eks_standard.Code}-${local.eks_standard.Feature}"
cluster_version     = "1.31"
eks_workload_type   = "ec2"

module "eks_main" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31.0"

  vpc_id = module.vpc_main.vpc_id
  # Only take non RFC 6598 private subnets
  control_plane_subnet_ids  = module.vpc_main.intra_subnets
  subnet_ids                = slice(module.vpc_main.private_subnets, 0, length(local.azs))
  cluster_service_ipv4_cidr = local.service_cidr
  enable_irsa               = true
  create_kms_key            = false
  cluster_version           = "1.31"
  cluster_name              = local.eks_naming_standard
  cluster_encryption_config = {
    provider_key_arn = module.kms_main.key_arn
    resources        = ["secrets"]
  }
  cluster_endpoint_public_access = var.env == "dev" ? true : false
  cluster_ip_family              = "ipv4"
  create_cloudwatch_log_group    = true
  cluster_addons = {
    eks-pod-identity-agent = {
      before_compute = true // create the pod identity agent before the compute resources
      most_recent    = true
    }
    vpc-cni = {
      before_compute = true // create the vpc-cni before the compute resources
      most_recent    = true
      # service_account_role_arn = module.vpc_cni_irsa.iam_role_arn // for using irsa (deprecated) change to pod identity
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
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      # service_account_role_arn = module.ebs_csi_irsa.iam_role_arn (deprecated)
      most_recent = true
    }

    amazon-cloudwatch-observability = {
      # service_account_role_arn = module.ebs_csi_irsa.iam_role_arn (deprecated)
      most_recent = true
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
      instance_types                 = var.env == "dev" ? ["t3.medium"] : ["m6i.large"]
      enable_bootstrap_user_data     = true
      capacity_type                  = var.env == "dev" ? "SPOT" : "ON_DEMAND"
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
      # update_config = {
      #   max_unavailable_percentage = 1 # or set `max_unavailable`
      # }
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

  # aws-auth configmap (deprecated use access_entries instead)
  # manage_aws_auth_configmap = true
  # aws_auth_users = [
  #   {
  #     userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  #     username = "root"
  #     groups   = ["system:masters"]
  #   }
  # ]

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = false

  access_entries = {
    # One access entry with a policy associated
    iac = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/iac"
      policy_associations = {
        iac = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    atlantis = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/atlantis-role"
      policy_associations = {
        atlantis = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    admin = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/imam.arief.rhmn@gmail.com"
      policy_associations = {
        iac = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = merge(
    local.tags,
    local.eks_standard,
    {
      "karpenter.sh/discovery" = local.eks_naming_standard
    }
  )
}

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


# EKS Pod Identity for VPC CNI
module "aws_vpc_cni_ipv4_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.7.0"

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
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.7.0"

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

# Create Storage Class for gp3
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  parameters = {
    type       = "gp3"
    iops       = "3000"
    throughput = "125"
  }
  volume_binding_mode = "WaitForFirstConsumer"
}

module "aws_cloudwatch_observability_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.7.0"

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
```

## Aurora MySQL

  Aurora MySQL is combination of performance, cost-efficiency, and MySQL compatibility. Aurora MySQL offers several advantages over standard RDS instances:
	- Performance: Aurora is optimized for high throughput and low latency. It can handle millions of requests per second, which is critical for applications that need to scale.
  - Managed Service: Aurora handles maintenance tasks like backups, failover, and updates automatically, freeing up operational overhead.
	- MySQL Compatibility: It’s fully compatible with MySQL, making it easy to migrate and integrate with existing systems.
	- Autoscaling: Aurora MySQL provides built-in autoscaling for both compute and storage, making it ideal for handling variable workloads.

### Private Database Setup

The Aurora cluster is deployed in private subnets, ensuring that it’s not exposed to the internet. This design significantly reduces the attack surface by restricting access to internal workloads running in private subnets, such as Kubernetes pods. Only authorized resources within the VPC can communicate with the database.

### Storage Encryption with KMS

All data stored in Aurora is encrypted using AWS KMS. This ensures that sensitive information is protected at rest. The KMS key used for encryption is managed centrally, giving us control over key rotation and access policies. Encryption extends to automated backups, snapshots, and replicas, ensuring end-to-end data security.

### IAM Database Authentication

The Aurora cluster is configured with IAM database authentication, which allows us to use IAM roles for database access instead of traditional username/password credentials. This approach is more secure because:
- There’s no need to manage passwords in the application code.
-	Access is tied to IAM roles, making it easier to enforce least-privilege policies and revoke access when needed.

### Autoscaling and Read Replicas

Autoscaling is enabled for the Aurora cluster, allowing it to dynamically adjust compute capacity based on traffic. This is particularly important for handling:
- High Traffic Spikes: During peak traffic, read replicas can scale up to handle increased read workloads, preventing bottlenecks.
- Connection Pooling Issues: By adding more read replicas during high traffic, Aurora ensures the application doesn’t hit connection limits, improving response times and user experience.

### Read Replicas

Aurora read replicas are crucial for scaling read-heavy workloads. Traffic can be distributed across replicas using a load balancer or connection pooling strategy. This not only improves performance but also reduces the load on the primary instance, ensuring smooth operation during traffic spikes.

### Secrets Management and Rotation

The Aurora cluster’s master password is managed using AWS Secrets Manager. Secrets Manager automatically rotates the password, ensuring it’s always up-to-date and reducing the risk of credential leaks. By integrating Secrets Manager with Aurora, applications can securely retrieve database credentials without hardcoding them.

Why Automatic Rotation?
- It eliminates manual processes for updating passwords, reducing human error.
- Credentials are updated seamlessly, ensuring minimal disruption to services.

### Snapshots for Backup and Recovery

Snapshots are an integral part of this setup for disaster recovery and data retention. While Aurora automatically performs backups, manual snapshots allow us to:
- Preserve Point-in-Time Data: Snapshots capture the state of the database at a specific time, which is helpful for compliance or testing.
- Disaster Recovery: In case of accidental data loss, snapshots can be used to restore the database quickly.

Performance Insights

Aurora is configured with Performance Insights, which provides detailed metrics for database performance. This helps in:
- Identifying slow queries or performance bottlenecks.
- Optimizing database configurations and query execution.

### Aurora: Talking is Cheap, Show Me the Code
Path: iac/deployment/cloud/main.tf
```hcl
  aurora_standard = {
    Unit    = var.unit
    Env     = var.env
    Code    = "rds-aurora"
    Feature = "main"
  }
  aurora_naming_standard = "${local.aurora_standard.Unit}-${local.aurora_standard.Env}-${local.aurora_standard.Code}-${local.aurora_standard.Feature}"

