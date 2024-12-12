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

Our Virtual Private Cloud (VPC) is the heart of our AWS setup. It makes sure all our AWS resources can talk to each other securely and work well together. We designed the VPC to be scalable, highly available, high-performing, secure, and cost-effective.

### Core Design
- Scalable: We use a CIDR block of 10.0.0.0/16 which gives us lots of IP addresses. This helps us add more resources easily as we grow. We also added a second CIDR block 100.64.0.0/16 for Kubernetes pods. This keeps pod IPs separate and avoids conflicts, so we never run out of IPs as our cluster gets bigger.
- Highly Available: Our VPC spreads resources across multiple Availability Zones (AZs). This means if one AZ has problems, our services stay up and running in other AZs. No single point of failure!
- High Performance: We use AWS services like NAT Gateways and Application Load Balancers (ALBs) to ensure fast and reliable communication between our resources. This setup helps keep our applications running smoothly.
- Secure: Security is a top priority. We isolate critical resources in private subnets and use security groups and network ACLs to control who can access what. Data is encrypted both in transit and at rest using AWS KMS and SSL certificates.
- Cost Optimized: We balance performance and cost by using resources wisely. For example, we use one NAT Gateway in development to save money and multiple NAT Gateways in production for reliability.

### Subnet Design

Our VPC has three types of subnets, each with a specific role. These subnets are spread across different AZs to keep things running even if one AZ fails.
- Public Subnets:
- Purpose: Host internet-facing services like NAT Gateways, ALBs, and bastion hosts for secure admin access.
- Interaction: ALBs handle incoming internet traffic and send it to our internal services. NAT Gateways let our private resources access the internet securely without being exposed directly.
- Setup: These subnets have public IPs and proper routing to manage both incoming and outgoing internet traffic.
- Private Subnets:
- Purpose: Hold important internal resources like EKS worker nodes and application pods.
- Interaction: These resources don’t have direct internet access. They use NAT Gateways to go out when needed. Tags like kubernetes.io/role/internal-elb help Kubernetes manage internal load balancers, and karpenter.sh/discovery helps with autoscaling.
- Setup: Private subnets keep our critical resources secure and allow them to scale easily as demand grows.
- Database Subnets:
- Purpose: Only for our Aurora database instances.
- Interaction: These subnets are extra secure and separate from other traffic. Only authorized application workloads can talk to the databases.
- Setup: Strict access controls keep our databases safe from unauthorized access.

### NAT Gateways

We use NAT Gateways to manage outbound internet traffic from our private subnets.
- Development: One NAT Gateway helps keep costs low.
- Production: Each AZ has its own NAT Gateway for better reliability. If one AZ or NAT Gateway fails, others keep working.

NAT Gateways are important because they let our private resources access the internet securely without being exposed. They also scale automatically to handle more traffic when needed.

Why This VPC Design Works
- Scalability: With a large IP range and separate blocks for pods, we can keep adding more resources without running out of IPs. Our setup supports growing workloads without issues.
- High Availability: By spreading subnets across multiple AZs, our services stay available even if one AZ has problems. This makes our system more resilient.
- High Performance: Using AWS services like NAT Gateways and ALBs ensures that our resources communicate quickly and reliably. This keeps our applications running smoothly.
- Security: Private subnets and strict access controls keep our important resources safe from the internet. Encryption protects our data both when it’s stored and when it’s moving around.
- Cost Optimization: We save money by using fewer NAT Gateways in development and scaling them in production as needed. This way, we get the best performance without overspending.

### Security Measures

Security is built into every part of our VPC:
- Network Isolation: Private subnets keep critical resources hidden from the internet. Only necessary services are in public subnets.
- Access Controls: Security groups and network ACLs control who can access what. Only allowed traffic can move between resources.
- Data Encryption: We use AWS KMS to encrypt sensitive data at rest. ALBs use SSL certificates from AWS ACM to secure data in transit.
- Managed Security Services: Tools like AWS WAF protect our APIs from common web attacks, adding an extra layer of security.
  
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

### Add-ons for Observability and Scalability

Several add-ons are installed to enhance the functionality and observability of the cluster:
- CloudWatch Observability: Provides centralized monitoring and logging for Kubernetes workloads. This simplifies debugging and ensures better visibility into the system performance.
- CoreDNS: Handles service discovery within the cluster.
- Kube-proxy: Manages network proxying for Kubernetes services.

### IAM Integration with Pod Identity

For managing permissions, the cluster uses EKS Pod Identity instead of the traditional IAM Roles for Service Accounts (IRSA). Pod Identity provides:
- Granular permissions: Pods can assume roles with minimal required permissions, enhancing security.
- Simpler configuration: It reduces the need for managing trust relationships manually.

## ALB as Ingress Controller and API Gateway

The design is how we expose our backend APIs to the public securely and efficiently. To do this, we use AWS API Gateway combined with an internal Application Load Balancer (ALB) as an ingress controller in our EKS cluster.

### Exposing APIs with API Gateway

To make our backend APIs accessible to users, I use AWS API Gateway. This service acts as a front door for our APIs, handling all the incoming requests from the internet. By using API Gateway, we can easily manage and scale our API traffic without worrying about the underlying infrastructure.

### Secure Authentication with AWS Cognito

Security is a top priority, so I use AWS Cognito to handle authentication. Cognito serves as our authorizer, ensuring that only authenticated clients can access our APIs. We set it up to use client credentials, which means that our applications need to provide valid credentials to get access tokens. This way, we keep unauthorized users out and protect our backend services from misuse.

### Integration with EKS ALB via VPC Link

Our EKS cluster uses an internal ALB as an ingress controller to manage traffic within the VPC. To connect API Gateway with this internal ALB, we use a VPC Link. This setup ensures that the API Gateway can securely route requests to our backend services running inside the EKS cluster without exposing the internal ALB to the public internet.

### Enhancing Security and Performance

To keep our application safe and perform well, I’ve added several security and performance features to API Gateway:
- Throttling Rate Limits: We set up throttling to control the number of requests a client can make in a given time period. This helps prevent abuse and ensures that our services remain available even under high load.
- CORS Configuration: Cross-Origin Resource Sharing (CORS) is configured to allow our frontend applications to interact with the API Gateway securely. This setup specifies which domains can make requests, what methods are allowed, and which headers can be used.
- Web Application Firewall (WAF): AWS WAF is integrated with API Gateway to protect our APIs from common web exploits like SQL injection and cross-site scripting. WAF rules help filter out malicious traffic before it reaches our backend services.

### Putting It All Together

By combining API Gateway with an internal ALB in EKS, and securing everything with Cognito, throttling, CORS, and WAF, we’ve built a robust and secure way to expose our backend APIs to the public. This architecture not only ensures that our APIs are safe and reliable but also makes it easy to scale and manage as our application grows.

## Aurora MySQL

Aurora MySQL is combination of performance, cost-efficiency, and MySQL compatibility. Aurora MySQL offers s built-in autoscaling for both compute and storage, making it ideal for handling variable workloads.

### Private Database Setup

The Aurora cluster is deployed in database subnets, ensuring that it’s not exposed to the internet. This design significantly reduces the attack surface by restricting access to internal workloads running in private subnets, such as Kubernetes pods. Only authorized resources within the VPC can communicate with the database.

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

### Performance Insights

Aurora is configured with Performance Insights, which provides detailed metrics for database performance. This helps in:
- Identifying slow queries or performance bottlenecks.
- Optimizing database configurations and query execution.


# How to Setup/Run the Infrastructure and Deploy the App
<p align="center">
  <img src="img/atlantis.png" alt="aws">
</p>

Cara cepatnya untuk setup/run infrastructure  menggunakan Terraform.
1. Install Terraform
2. Develop code terraform untuk resource yang kita buat, 
3. Jalan kan terraform init, plan, dan apply.

Untuk mendeploy kita bisa menggunakan helm
1. Install helm
2. helm repo add https://runatlantis.github.io/helm-char
3. Jalankan hellm install -f values.yaml

Pada tahap awal kita masih perlu untuk membuat resource menggunakan terraform secara manual.
Cara ini tidak efektif dan tidak efisien. Kita harus mensetup infrastruktur dan mendeploy aplikasi kedepan harus menerapkan membangun self service model 
agar developer dapat memanaged aplikasinya sendiri.
Kita membutuhkan EKS telah ready, Atlantis dan ArgoCD  telah terinstall lalu menggunakan argocd.


Berikut terraform provider
1. Deploy Atlantis dan ArgoCD pada EKS cluster menggunakan helm provider.
Untuk mendeploy atlantis dan ArgocD, kita harus makesure aws-alb-ingress-controller dan external-dns telah terinstall pada eks cluster. Agar saat ingress kita terbuat, alb-ingress-controller dapat membuat ALB dan external-dns dapat membuat record di route53 secara otomatis.
2. Lalu kita membuatkan IAM provider untuk membuat role dan policy yang dibutuhkan oleh atlantis dan argocd kita bisa menggunakan EKS Pod Identity atau IRSA. Tapi disini saya menggunakan EKS Pod Identity.
Contoh terraform code:
```hcl
provider "aws" {
  region = local.region
  dynamic "assume_role" {
    # If the current environment is running on EC2 then use instance profile to access AWS resources
    for_each = local.is_ec2_environment ? [] : [1]
    content {
      role_arn = "arn:aws:iam::124456474132:role/iac"
    }
  }
}

# Create Helm provider
provider "helm" {
  kubernetes {
    host                   = module.eks_main.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_main.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}


# Atlantis
module "atlantis" {
  source = "../../modules/helm"

  region           = var.region
  standard         = local.atlantis_standard
  repository       = "https://runatlantis.github.io/helm-charts"
  chart            = "atlantis"
  values           = ["${file("manifest/${local.atlantis_standard.Feature}.yaml")}"]
  namespace        = "atlantis"
  create_namespace = true
  dns_name         = local.route53_domain_name
  extra_vars = {
    github_user = var.github_owner

    # ingress
    ingress_enabled    = true
    ingress_class_name = "alb"
    # ingress alb
    alb_certificate_arn              = module.acm_main.acm_certificate_arn
    alb_ssl_policy                   = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    alb_backend_protocol             = "HTTP"
    alb_listen_ports                 = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
    alb_scheme                       = "internet-facing"
    alb_target_type                  = "ip"
    alb_group_name                   = "${var.unit}-${var.env}-${local.atlantis_standard.Code}-ingress"
    alb_group_order                  = "2"
    alb_healthcheck_path             = "/"
    alb_ssl_redirect                 = 443
    aws_alb_service_type             = "ClusterIP"
    aws_alb_backend_protocol_version = "GRPC"
  }
  helm_sets_sensitive = [
    {
      name  = "github.token"
      value = jsondecode(data.aws_secretsmanager_secret_version.secret_iac_current.secret_string)["github_token"]
    },
    {
      name  = "github.secret"
      value = random_password.atlantis_github_secret.result
    },
  ]
  depends_on = [
    module.eks_main,
  ]
}

module "atlantis_custom_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.7.0"

  name            = "${local.atlantis_standard.Feature}-role"
  use_name_prefix = false

  # ArgoCD Vault Plugin (AVP) is installed in the argocd-repo-server 
  # So we need to attach the policy to the argocd-repo-server service account
  association_defaults = {
    namespace       = local.atlantis_standard.Feature
    service_account = "${local.atlantis_standard.Feature}-sa"
    tags            = { App = local.atlantis_standard.Feature }
  }

  associations = {
    main = {
      cluster_name = module.eks_main.cluster_name
    }
  }

  attach_custom_policy    = true
  source_policy_documents = [data.aws_iam_policy_document.atlantis_policy.json]

  tags = local.tags
}

# ArgoCD
# ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes.
module "argocd" {
  source = "../../modules/helm"

  region           = var.region
  standard         = local.argocd_standard
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  values           = ["${file("manifest/${local.argocd_standard.Feature}.yaml")}"]
  namespace        = "argocd"
  create_namespace = true
  dns_name         = local.route53_domain_name
  extra_vars = {
    github_orgs      = var.github_orgs
    github_client_id = var.github_oauth_client_id
    ARGOCD_VERSION   = var.argocd_version
    AVP_VERSION      = var.argocd_vault_plugin_version
    server_insecure  = true

    # ref https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd
    # ingress
    ingress_enabled    = true
    ingress_controller = "aws"
    ingress_class_name = "alb"
    # ingress alb
    alb_certificate_arn              = module.acm_main.acm_certificate_arn
    alb_ssl_policy                   = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    alb_backend_protocol             = "HTTP"
    alb_listen_ports                 = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
    alb_scheme                       = "internet-facing"
    alb_target_type                  = "ip"
    alb_group_name                   = "${var.unit}-${var.env}-${local.argocd_standard.Code}-ingress"
    alb_group_order                  = "1"
    alb_healthcheck_path             = "/"
    alb_ssl_redirect                 = 443
    aws_alb_service_type             = "ClusterIP"
    aws_alb_backend_protocol_version = "GRPC"
  }
  helm_sets_sensitive = [
    {
      name  = "configs.secret.githubSecret"
      value = random_password.argocd_github_secret.result
    },
    {
      name  = "configs.secret.extra.dex\\.github\\.clientSecret"
      value = jsondecode(data.aws_secretsmanager_secret_version.secret_iac_current.secret_string)["github_oauth_client_secret"]
    },
  ]
  depends_on = [
    module.eks_main,
  ]
}

# ArgoCD Vault Plugin (AVP) Pod Identity
module "avp_custom_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.7.0"

  name            = "avp_role"
  use_name_prefix = false

  # ArgoCD Vault Plugin (AVP) is installed in the argocd-repo-server 
  # So we need to attach the policy to the argocd-repo-server service account
  association_defaults = {
    namespace       = "argocd"
    service_account = "argocd-repo-server"
    tags            = { App = "avp" }
  }

  associations = {
    main = {
      cluster_name = module.eks_main.cluster_name
    }
  }

  attach_custom_policy    = true
  source_policy_documents = [data.aws_iam_policy_document.avp_policy.json]

  tags = local.tags
}
```

Berikut manifestnya:
iac/deployment/cloud/manifest/atlantis.yaml
```yaml
orgAllowlist: github.com/greyhats13/*

environment:
  GITHUB_OWNER: ${extra_vars.github_user}

environmentSecrets:
  - name: GITHUB_TOKEN
    secretKeyRef:
      name: ${unit}-${env}-${code}-${feature}-webhook
      key: github_token

github:
  user: ${extra_vars.github_user}

repoConfig: |
 ---
 repos:
 - id: /.*/
   branch: /.*/
   repo_config_file: iac/atlantis.yaml
   plan_requirements: []
   apply_requirements: []
   workflow: default
   allowed_overrides: [apply_requirements, plan_requirements]
   allow_custom_workflows: false
 workflows:
   default:
     plan:
       steps: [init, plan]
     apply:
       steps: [apply]
serviceAccount:
  name: ${feature}-sa

service:
  type: ClusterIP
  port: 80
  targetPort: 4141

ingress:
  enabled: ${extra_vars.ingress_enabled}
  ingressClassName: ${extra_vars.ingress_class_name}
  annotations:
    external-dns.alpha.kubernetes.io/hostname: ${feature}.${dns_name}
    external-dns.alpha.kubernetes.io/ttl: '300'
    alb.ingress.kubernetes.io/group.name: ${extra_vars.alb_group_name}
    alb.ingress.kubernetes.io/certificate-arn: ${extra_vars.alb_certificate_arn}
    alb.ingress.kubernetes.io/ssl-policy: ${extra_vars.alb_ssl_policy}
    alb.ingress.kubernetes.io/backend-protocol: ${extra_vars.alb_backend_protocol}
    alb.ingress.kubernetes.io/listen-ports: '${extra_vars.alb_listen_ports}'
    alb.ingress.kubernetes.io/scheme: ${extra_vars.alb_scheme}
    alb.ingress.kubernetes.io/target-type: ${extra_vars.alb_target_type}
    alb.ingress.kubernetes.io/group.order: '${extra_vars.alb_group_order}'
    alb.ingress.kubernetes.io/healthcheck-path: ${extra_vars.alb_healthcheck_path}
    alb.ingress.kubernetes.io/ssl-redirect: '${extra_vars.alb_ssl_redirect}'
  host: ${feature}.${dns_name}
  tls:
    - hosts:
        - ${feature}.${dns_name}

volumeClaim:
  storageClassName: gp3
```

Berikut manifestnya:
iac/deployment/cloud/manifest/argocd.yaml
```yaml
# Ref: https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd
global:
  domain: "${feature}.${dns_name}"

configs:
  cm:
    url: "https://${feature}.${dns_name}"
    dex.config: |
      connectors:
        - type: github
          id: github
          name: GitHub
          config:
            clientID: ${extra_vars.github_client_id}
            clientSecret: $argocd-secret:dex.github.clientSecret
            redirectURI: 'https://${feature}.${dns_name}/api/dex/callback'
            orgs:
              - name: ${extra_vars.github_orgs}
  params:
    server.insecure: ${extra_vars.server_insecure}
  rbac:
    policy.default: role:readonly
    policy.csv: |
      # default policy
      p, role:readonly, applications, get, */*, allow
      p, role:readonly, certificates, get, *, allow
      p, role:readonly, clusters, get, *, allow
      p, role:readonly, repositories, get, *, allow
      p, role:readonly, projects, get, *, allow
      p, role:readonly, accounts, get, *, allow
      p, role:readonly, gpgkeys, get, *, allow
      p, role:readonly, logs, get, */*, allow
      # admin policy
      p, role:devops-role, applications, create, */*, allow
      p, role:devops-role, applications, update, */*, allow
      p, role:devops-role, applications, delete, */*, allow
      p, role:devops-role, applications, sync, */*, allow
      p, role:devops-role, applications, override, */*, allow
      p, role:devops-role, applications, action/*, */*, allow
      p, role:devops-role, applicationsets, get, */*, allow
      p, role:devops-role, applicationsets, create, */*, allow
      p, role:devops-role, applicationsets, update, */*, allow
      p, role:devops-role, applicationsets, delete, */*, allow
      p, role:devops-role, certificates, create, *, allow
      p, role:devops-role, certificates, update, *, allow
      p, role:devops-role, certificates, delete, *, allow
      p, role:devops-role, clusters, create, *, allow
      p, role:devops-role, clusters, update, *, allow
      p, role:devops-role, clusters, delete, *, allow
      p, role:devops-role, repositories, create, *, allow
      p, role:devops-role, repositories, update, *, allow
      p, role:devops-role, repositories, delete, *, allow
      p, role:devops-role, projects, create, *, allow
      p, role:devops-role, projects, update, *, allow
      p, role:devops-role, projects, delete, *, allow
      p, role:devops-role, accounts, update, *, allow
      p, role:devops-role, gpgkeys, create, *, allow
      p, role:devops-role, gpgkeys, delete, *, allow
      p, role:devops-role, exec, create, */*, allow
      # set admin policy for devops team in github orgs
      g, ${extra_vars.github_orgs}:devops, role:devops-role
      g, devops, role:devops-role
  # ref: https://github.com/argoproj-labs/argocd-vault-plugin/blob/main/manifests/cmp-sidecar/cmp-plugin.yaml
  cmp:
    # -- Create the argocd-cmp-cm configmap
    create: true
    plugins:
      argocd-vault-plugin-helm:
        allowConcurrency: true

        # Note: this command is run _before_ any Helm templating is done, therefore the logic is to check
        # if this looks like a Helm chart
        discover:
          find:
            command:
              - sh
              - "-c"
              - "find . -name 'Chart.yaml' && find . -name 'values.yaml'"
        generate:
          # **IMPORTANT**: passing effectively allows users to run arbitrary code in the Argo CD 
          # repo-server (or, if using a sidecar, in the plugin sidecar). Only use this when the users are completely trusted. If
          # possible, determine which Helm arguments are needed by your users and explicitly pass only those arguments.
          command:
            - sh
            - "-c"
            - |
              helm template $ARGOCD_APP_NAME -n $ARGOCD_APP_NAMESPACE . --include-crds |
              argocd-vault-plugin generate -
        lockRepo: false
      argocd-vault-plugin:
        allowConcurrency: true
        discover:
          find:
            command:
              - sh
              - "-c"
              - "find . -name '*.yaml' | xargs -I {} grep \"<path\\|avp\\.kubernetes\\.io\" {} | grep ."
        generate:
          command:
            - argocd-vault-plugin
            - generate
            - "."
        lockRepo: false

# ref: https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/
server:
  ingress:
    enabled: ${extra_vars.ingress_enabled}
    controller: ${extra_vars.ingress_controller}
    ingressClassName: ${extra_vars.ingress_class_name}
    annotations:
      external-dns.alpha.kubernetes.io/hostname: ${feature}.${dns_name}
      external-dns.alpha.kubernetes.io/ttl: '300'
      alb.ingress.kubernetes.io/group.name: ${extra_vars.alb_group_name}
      alb.ingress.kubernetes.io/certificate-arn: ${extra_vars.alb_certificate_arn}
      alb.ingress.kubernetes.io/ssl-policy: ${extra_vars.alb_ssl_policy}
      alb.ingress.kubernetes.io/backend-protocol: ${extra_vars.alb_backend_protocol}
      alb.ingress.kubernetes.io/listen-ports: '${extra_vars.alb_listen_ports}'
      alb.ingress.kubernetes.io/scheme: ${extra_vars.alb_scheme}
      alb.ingress.kubernetes.io/target-type: ${extra_vars.alb_target_type}
      alb.ingress.kubernetes.io/group.order: '${extra_vars.alb_group_order}'
      alb.ingress.kubernetes.io/healthcheck-path: ${extra_vars.alb_healthcheck_path}
      alb.ingress.kubernetes.io/ssl-redirect: '${extra_vars.alb_ssl_redirect}'
    aws:
      serviceType: ${extra_vars.aws_alb_service_type}
      backendProtocolVersion: ${extra_vars.aws_alb_backend_protocol_version}
# ref: https://github.com/argoproj-labs/argocd-vault-plugin/blob/main/manifests/cmp-sidecar/argocd-repo-server.yaml
repoServer:
  serviceAccount:
    name: ${feature}-repo-server
    # Not strictly necessary, but required for passing AVP configuration from a secret and for using Kubernetes auth to Hashicorp Vault
    automountServiceAccountToken: true
  volumes:
    - configMap:
        name: argocd-cmp-cm
      name: argocd-cmp-cm
    - name: cmp-tmp
      emptyDir: {}
    - name: custom-tools
      emptyDir: {}
  initContainers:
    - name: download-tools
      image: registry.access.redhat.com/ubi8
      env:
        - name: AVP_VERSION
          value: ${extra_vars.AVP_VERSION}
      command: [sh, -c]
      args:
        - >-
          curl -L https://github.com/argoproj-labs/argocd-vault-plugin/releases/download/v${extra_vars.AVP_VERSION}/argocd-vault-plugin_${extra_vars.AVP_VERSION}_linux_amd64 -o argocd-vault-plugin &&
          chmod +x argocd-vault-plugin &&
          mv argocd-vault-plugin /custom-tools/

      volumeMounts:
        - mountPath: /custom-tools
          name: custom-tools
  extraContainers:
      # argocd-vault-plugin with Helm
    - name: avp-helm
      command: [/var/run/argocd/argocd-cmp-server]
      image: quay.io/argoproj/argocd:${extra_vars.ARGOCD_VERSION}
      securityContext:
        runAsNonRoot: true
        runAsUser: 999
      volumeMounts:
        - mountPath: /var/run/argocd
          name: var-files
        - mountPath: /home/argocd/cmp-server/plugins
          name: plugins
        - mountPath: /tmp
          name: cmp-tmp

        # Register plugins into sidecar
        - mountPath: /home/argocd/cmp-server/config/plugin.yaml
          subPath: argocd-vault-plugin-helm.yaml
          name: argocd-cmp-cm

        # Important: Mount tools into $PATH
        - name: custom-tools
          subPath: argocd-vault-plugin
          mountPath: /usr/local/bin/argocd-vault-plugin
    - name: avp
      command: [/var/run/argocd/argocd-cmp-server]
      image: quay.io/argoproj/argocd:${extra_vars.ARGOCD_VERSION}
      securityContext:
        runAsNonRoot: true
        runAsUser: 999
      volumeMounts:
        - mountPath: /var/run/argocd
          name: var-files
        - mountPath: /home/argocd/cmp-server/plugins
          name: plugins
        - mountPath: /tmp
          name: cmp-tmp

        # Register plugins into sidecar
        - mountPath: /home/argocd/cmp-server/config/plugin.yaml
          subPath: argocd-vault-plugin.yaml
          name: argocd-cmp-cm

        # Important: Mount tools into $PATH
        - name: custom-tools
          subPath: argocd-vault-plugin
          mountPath: /usr/local/bin/argocd-vault-plugin
```


2. Setelah kita atlantis terinstall. Untuk 