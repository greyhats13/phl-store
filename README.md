# Instructions
Starting from an AWS empty environment, setup a Kubernetes cluster and Aurora MySQL cluster including all the necessary resources
using Terraform.
Next deploy a sample application phl-store to the Kubernetes Cluster (preferably with Helm). It is a simple CRUD application and should
be accessible from the outside world. The docker image URL can be found at https://hub.docker.com/r/zylwin/phl-store . The app uses
MySQL as the database to store and retrieve data. The config file is mounted as /config/config.json . The docker-compose file is
attached below for your reference.
For the application deployment, use any CI/CD tools of your choice.

# Instructions
Submission
For your submission, create a private Github repository and include the following
1. Architectural diagram to explain your architecture.
2. The relevant configuration scripts (eg: Terraform).
3. In the README, include
a. Instruction on how to setup/run the infrastructure and deploy the app
b. Include high level steps on how would you manage the secrets and configuration changes
c. Also include high level steps to make this infrastructure more secure, automate and reliable

# AWS Infrastructure

<p align="center">
  <img src="img/aws.png" alt="aws">
</p>
## VPC

The VPC in this setup is designed to be the backbone of our AWS infrastructure. It provides isolated networking for all resources, ensuring efficient communication while maintaining strict security boundaries. The CIDR block for the VPC is 10.0.0.0/16, giving us a large pool of IP addresses to allocate across subnets for different use cases.

I’ve also added a secondary CIDR block, 100.64.0.0/16, which follows the RFC6598 standard. This block is specifically reserved for Kubernetes pods in EKS, making sure that pod IP addresses don’t conflict with node IPs or on-premise network configurations. By separating pod IPs into their own CIDR block, I avoid running out of IPs in the primary VPC range even as the cluster scales.

### Subnet Design

The VPC has three types of subnets: public, private, and database subnets. These subnets are distributed across multiple Availability Zones (AZs) for fault tolerance.
	•	Public Subnets are where internet-facing resources live, like NAT Gateways and Application Load Balancers (ALBs). These are also used for bastion hosts when you need secure administrative access to private resources. Public subnets have public IPs and are configured with proper routing to handle incoming and outgoing internet traffic. The ALBs distribute traffic to internal workloads, and the NAT Gateways allow private subnets to securely access external resources without exposing themselves.
	•	Private Subnets are used for critical internal resources like Kubernetes worker nodes (EKS nodes) and application pods. These subnets don’t have direct internet access. Instead, all outbound traffic from these subnets goes through the NAT Gateways. Kubernetes workloads are dynamically scaled within these subnets, thanks to tagging for auto-discovery. Tags like kubernetes.io/role/internal-elb help Kubernetes know which subnets to use for internal load balancers, while tags like karpenter.sh/discovery let Karpenter manage autoscaling based on workload demands.
	•	Database Subnets are isolated further, used only for our Aurora database instances. They are designed to keep the database secure and separate from application traffic, with strict access controls.

### NAT Gateways

I’ve deployed NAT Gateways in public subnets to handle outbound internet traffic from private resources. For the development environment, I personally an use a single NAT Gateway to optimize costs. In production, each AZ has its own NAT Gateway for high availability. This setup ensures that even if one AZ or NAT Gateway fails, resources in other AZs can still access the internet.

NAT Gateways are crucial for security because they allow private resources to access external services (like downloading updates) without exposing themselves directly to the internet. Plus, they scale automatically to handle more traffic as needed, which makes them a perfect fit for a scalable architecture.

### Scalability and Availability

The VPC is designed to support growth and handle failures gracefully. By spreading subnets across multiple AZs, we ensure that workloads remain available even if one AZ goes down. For Kubernetes, the RFC6598 secondary CIDR block provides a huge IP range dedicated to pods, so scaling up workloads will never run into IP address exhaustion issues. Additionally, resources like NAT Gateways, ALBs, and EKS nodes are designed to scale automatically, ensuring the system can handle sudden traffic spikes.

### Security

Security is baked into every layer of this design. Private subnets ensure that critical resources are not directly exposed to the internet. Security groups and network ACLs enforce strict traffic controls, only allowing necessary communication between resources. Database subnets are completely isolated, with access restricted to specific application workloads.

The encryption is handled using AWS KMS for sensitive data, and the ALBs use SSL certificates from AWS ACM for secure communication. This way, data is always protected whether it’s at rest or in transit.

This VPC setup is a solid foundation for our infrastructure. It’s scalable, secure, and built to handle failures without downtime. By following AWS best practices and using tools like Terraform, I’ve ensured that the network is robust and future-proof.

### VPC Terraform Configuration
```hcl
Satu menggunakan RFC 1918 CIDR block dan satu lagi menggunakan RFC 6598 CIDR block.
locals.tf
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
```

##
```hcl
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
### Public Subnet
Public subnet dirancang memiliki 2 subnet sebanyak AZ yang ada diregion
```hcl
1. Public Subnet digunakan untuk menempatkan resource berikut:
1. NAT Gateway untuk aplikasi yang ada di private subnet dan database subnet agar bisa mengakses internat dan melakukan patching
2. Elastic Load Balancer (ELB) untuk menempatkan aplikasi yang bisa diakses dari internet seperti ArgoCD dan

2. Public Subnet digunakan untuk menempatkan
- Argo


# Self Service Model
<p align="center">
  <img src="img/atlantis.png" alt="atlantis">
</p>

# CI/CD with GitOps
<p align="center">
  <img src="img/cicd.png" alt="cicd">
</p>