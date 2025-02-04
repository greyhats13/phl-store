# Instructions

- Starting from an AWS empty environment, setup Kubernetes cluster and Aurora MySQL cluster including all the necessary resources
using Terraform.
- Next deploy a sample application phl-store to the Kubernetes Cluster (preferably with Helm). It's a simple CRUD application and should
be accessible from the outside world. The docker image URL can be found at https://hub.docker.com/r/zylwin/phl-store . 
- The app uses MySQL as the database to store & retrieve data. The config file is mounted as /config/config.json . The docker-compose file is below for your reference.
For the application deployment, use any CI/CD tools of your choice.

# Submission

For our submission, create a private Github repository & include the following

1. Architectural diagram to explain yur architecture.
2. The relevant configuration scripts (eg: Terraform).
3. In the README, include
   - Instruction on how to setup/run the infrastructure & deploy the app
   - Include high level steps on how would you manage the secrets & configuration change
   - Also include high level steps to make this infrastructure more secure, automate & reliable

# Table of Contents

- [Instructions](#instructions)
- [Submission](#submission)
- [AWS Infrastructure Design](#aws-infrastructure-design)
  - [VPC](#vpc)
    - [Subnets](#subnets)
    - [NAT Gateways](#nat-gateways)
    - [Scalability and Availability](#scalability-and-availability)
    - [Security](#security)
  - [Elastic Kubernetes Service (EKS)](#elastic-kubernetes-service-eks)
    - [EKS Cluster Configuration](#eks-cluster-configuration)
    - [Why BottleRocket?](#why-bottlerocket)
    - [Node Groups & Autoscaling](#node-groups--autoscaling)
    - [Storage & Volume Management](#storage--volume-management)
    - [Networking with VPC CNI](#networking-with-vpc-cni)
    - [Add-ons for Observability & Scalability](#add-ons-for-observability--scalability)
    - [IAM Integration with Pod Identity](#iam-integration-with-pod-identity)
  - [ALB as Ingress Controller & API Gateway](#alb-as-ingress-controller--api-gateway)
    - [Exposing APIs with API Gateway](#exposing-apis-with-api-gateway)
    - [Secure Authentication with AWS Cognito](#secure-authentication-with-aws-cognito)
    - [Integration with EKS ALB via VPC Link](#integration-with-eks-alb-via-vpc-link)
    - [Enhancing Security & Performance](#enhancing-security--performance)
    - [Putting It All Together](#putting-it-all-together)
  - [Aurora MySQL](#aurora-mysql)
    - [Private Database Setup](#private-database-setup)
    - [Storage Encryption with KMS](#storage-encryption-with-kms)
    - [IAM Database Authentication](#iam-database-authentication)
    - [Autoscaling & Read Replicas](#autoscaling--read-replicas)
    - [Read Replicas](#read-replicas)
    - [Secrets Management & Rotation](#secrets-management--rotation)
    - [Snapshots for Backup & Recovery](#snapshots-for-backup--recovery)
    - [Performance Insights](#performance-insights)
- [How to Setup/Run the Infrastructure & Deploy the App](#how-to-setuprun-the-infrastructure--deploy-the-app)
  - [Prerequisites](#prerequisites)
  - [ArgoCD](#argocd)
  - [Atlantis](#atlantis)
  - [Prepare Manifests for Atlantis & ArgoCD](#prepare-manifests-for-atlantis--argocd)
  - [Self Service Model with Atlantis](#self-service-model-with-atlantis)
  - [Deploying Service using GitOps](#deploying-service-using-gitops)
  - [Securing the Application Secret](#securing-the-application-secret)
    - [Preparation](#preparation)
    - [Install ArgoCD & AVP on EKS](#install-argocd--avp-on-eks)
    - [Set Up IAM Policy for AVP](#set-up-iam-policy-for-avp)
    - [Attach IAM Policy to ArgoCD Repo Server](#attach-iam-policy-to-argocd-repo-server)
    - [Create Secret Template for Helm Chart](#create-secret-template-for-helm-chart)
    - [Prepare Secret Annotations in values.yaml](#prepare-secret-annotations-in-valuesyaml)
    - [Mount Secrets in Deployment](#mount-secrets-in-deployment)
    - [Replace Placeholders with Secrets](#replace-placeholders-with-secrets)
- [Designing scalable, secure & reliable application](#designing-scalable-secure--reliable-application)
  - [Use Distroless Image for Security](#use-distroless-image-for-security)
  - [Implement HPA for Pod Autoscaling and Karpenter for Node Autoscaling](#implement-hpa-for-pod-autoscaling-and-karpenter-for-node-autoscaling)
  - [Increase Pod Security](#increase-pod-security)
  - [Use API Gateway for Security & Rate Limiting](#use-api-gateway-for-security--rate-limiting)
  - [Use Redis for Caching](#use-redis-for-caching)
  - [Use Distroless Image for Security](#use-distroless-image-for-security)

# AWS Infrastructure Design
Here the architectural diagram, how we design the AWS infrastructure for the phl-store application to make it more secure, automated, & reliable.
<p align="center">
  <img src="img/aws.png" alt="aws">
</p>

All the design diagram is implemented in the Terraform code. The phl-store repository is mono repo where Terraform code, GitOps repo (Helm), & services are all stored in one repository.

## VPC

Our VPC is like the main highway for all our AWS stuff. It keeps everything nicely separated and secure, making sure our resources talk to each other smoothly without any unwanted visitors. We chose the CIDR block 10.0.0.0/16, which gives us plenty of IP addresses to spread out across different subnets for various needs.

To keep things running smoothly with Kubernetes in EKS, we added another CIDR block, 100.64.0.0/16, following the RFC6598 standard. This extra block is just for our Kubernetes pods, so their IPs don’t clash with the main VPC or any of our on-site networks. By having a separate range for pods, we ensure that as our cluster grows, we won’t run out of IP addresses in the main VPC.

### Subnets

We set up three kinds of subnets: public, private, & database. These are spread out over multiple Availability Zones (AZs) to make sure everything keeps running even if one zone has issue.

- **Public Subnets** are where things like NAT Gateways and ALB live. These subnets have public IPs & handle internet traffic. We also use them for bastion hosts when we need secure admin access to our private resources. The ALBs help distribute traffic to our internal services, & the NAT Gateways let our private subnets reach the internet safely without being directly exposed.

- **Private Subnets** are for our important internal stuff like Kubernetes worker nodes and application pods. These don’t have direct internet access. Instead, any outgoing traffic goes through the NAT Gateways. This setup helps us scale our Kubernetes workloads easily without worrying about IP address limits, thanks to tags that help with auto-discovery and autoscaling.

- **Database Subnets** are even more locked down, used only for our Aurora databases. They’re kept separate from the rest of the traffic to keep our data safe and secure, with strict access rules in place.

### NAT Gateways

We placed NAT Gateways in the public subnets to manage internet traffic from our private resources. For our development environment, we use just one NAT Gateway to keep costs down. In production, each AZ has its own NAT Gateway to ensure high availability. This way, if one AZ or NAT Gateway has issues, the others can keep things running smoothly.

NAT Gateways are great for security because they let our private resources reach out to the internet without being directly exposed. They also automatically scale to handle more traffic as needed, which is perfct for our growing and changing architecture.

### Room for Scalability and Availability

Our VPC is built to grow & handle failures without any obsta . By spreading our subnets across multiple AZs, we make sure that our services stay up even if one AZ has problems. We setup seconday CIDR block using RFC65898 so EKS nodes wont run out of IPs as we add more pod. Plus, things like NAT Gateways, ALBs, and EKS nodes can scale automatically to handle sudden increases in traffic, keeping everything fast & reliable.

### Security

Security is a top priority in our VPC design. Private subnets keep our critical resources hidden from the internet, and we use security groups and network ACLs to tightly control what traffic is allowed between resources. Our database subnets are completely isolated, making sure only the right parts of our application can talk to the database.

We use AWS KMS to encrypt sensitive data, and our ALBs have SSL certificates from AWS ACM to secure all communications. This means our data is always protected, whether it’s being stored or moving around.

Overall, our VPC setup gives us a strong, secure foundation that's ready to scale and handle any challenges. By following AWS best practices and using tools like Terraform, we've made sure our network is not only robust but also ready for the future.

## Elastic Kubernetes Service (EKS)

The EKS setup in this design is built for running containerized workloads efficiently. It takes advantage of AWS-native tools & Kubernetes features to ensure high performance, availability, & robust security. By using modules, we’ve automated many configurations, such as creating all required security groups for the control plane, nodes, & other components.

### EKS Cluster Configuration

The EKS cluster runs Kubernetes version 1.31 & is designed to operate in a private networking setup. The control plane spans multiple AZs, ensuring high availability. All communication between the control plane & worker nodes is encrypted for security.

The VPC’s subnets are configured to support the cluster needs:

- The control plane uses private subnets for communication, ensuring that it is isolated from public exposure.
- Worker nodes & pods run in private subnets to minimize exposure while allowing managed traffic routing through NAT Gateways & ALBs.

### Why BottleRocket?

The worker nodes in the managed node group use BottleRocket as the AMI. This is a lightweight, purpose built OS for containerized workloads & it comes with several advantages:

- Performance: Since it’s stripped down to just the essentials for running containers, it boots faster & uses fewer resources compared to general-purpose OSes.
- Security: BottleRocket minimizes the attack surface by removing unnecessary packages & includes built-in hardening features like kernel lockdown. It integrates seamlessly with AWS services like SSM for secure management.

### Node Groups & Autoscaling

The cluster has a managed node group for critical workloads that require high reliability. These nodes:

- Run on On-Dem& instances to ensure stability during normal traffic conditions.
- Have a fixed size (2 nodes) to avoid disruption from frequent scaling events.

For handling dynamic workloads, the cluster relies on Karpenter. Karpenter automatically provisions nodes based on dem&, offering rapid scaling & cost efficiency. This separation of critical & dynamic workloads ensures stability while maintaining flexibility.

### Storage & Volume Management

The setup includes EBS CSI (Container Storage Interface) for Kubernetes, which allows the cluster to provision storage dynamically. We’ve configured gp3 volumes as the default storage class. The benefits of gp3 are:

- Higher performance: With up to 3,000 IOPS & 125 MiB/s throughput, gp3 volumes provide consistent performance.
- Cost efficiency: gp3 is cheaper than gp2 for equivalent performance.
- Encryption: All volumes are encrypted using AWS KMS secure data at rest.

### Networking with VPC CNI

The cluster uses the AWS VPC CNI plugin to manage pod networking. Its is configured to use the secondary CIDR block (RFC6598, 100.64.0.0/16) to ensure there are enough IPs for pods, even in large scale deployments. This separation also avoids conflicts with the primary CIDR & simplifies integration with on-prem networks.

The VPC CNI plugin is enhanced with:

- Prefix delegation: This increases the number of available IPs per ENI, reducing the risk of IP exhaustion.
- Custom ENI configuration: Subnets & security groups are explicitly defined, providing fine-grained control over network access.

### Add-ons for Observability & Scalability

Several add-ons are installed to enhance the functionality & observability of the cluster:

- CloudWatch Observability: Provide centralizd monitoring & logging for Kubernetes workloads. This simplify debugging & ensures better visibility into the system performance.
- CoreDNS: handles service discovery within the cluster.
- Kube-proxy: Manages network proxying for Kubernetes services.

### IAM Integration with Pod Identity

For managing permissions, the cluster uses EKS Pod Identity instead of the traditional IAM Roles for Service Accounts (IRSA). Pod Identity provides:

- Granular permissions: Pods can assume roles with minimal required permissions, enhancing security.
- Simpler configuration: It reduces the need for managing trust relationships manually.

## ALB as Ingress Controller & API Gateway

The design is how we expose our backend APIs to the public securely & efficiently. To do this, we use AWS API Gateway combined with an internal Application Load Balancer (ALB) as an ingress controller in our EKS cluster.

### Exposing APIs with API Gateway

To make our backend APIs accessible to users, I use AWS API Gateway. This service acts as a front door for our APIs, handling all the incoming requests from the internet. By using API Gateway, we can easily manage & scale our API traffic without worrying about the underlying infrastructure.

### Secure Authentication with AWS Cognito

Security is a top priority, so I use AWS Cognito to handle authentication. Cognito serves as our authorizer, ensuring that only authenticated clients can access our APIs. We set it up to use client credentials, which means that our applications need to provide valid credentials to get access tokens. This way, we keep unauthorized users out & protect our backend services from misuse.

### Integration with EKS ALB via VPC Link

Our EKS cluster uses an internal ALB as an ingress controller to manage traffic within the VPC. To connect API Gateway with this internal ALB, we use a VPC Link. This setup ensures that the API Gateway can securely route requests to our backend services running inside the EKS cluster without exposing the internal ALB to the public internet.

### Enhancing Security & Performance

To keep our application safe & perform well, I’ve added several security & performance features to API Gateway:

- Throttling Rate Limits: We set up throttling to control the number of requests a client can make in a given time period. This helps prevent abuse & ensures that our services remain available even under high load.
- CORS Configuration: Cross-Origin Resource Sharing (CORS) is configured to allow our frontend applications to interact with the API Gateway securely. This setup specifies which domains can make requests, what methods are allowed, & which headers can be used.
- Web Application Firewall (WAF): AWS WAF is integrated with API Gateway to protect our APIs from common web exploits like SQL injection & cross-site scripting. WAF rules help filter out malicious traffic before it reaches our backend services.

### Putting It All Together

By combining API Gateway with an internal ALB in EKS, & securing everything with Cognito, throttling, CORS, & WAF, we’ve built a robust & secure way to expose our backend APIs to the public. This architecture not only ensures that our APIs are safe & reliable but also makes it easy to scale & manage as our application grows.

## Aurora MySQL

Aurora MySQL is combination of performance, cost-efficiency, & MySQL compatibility. Aurora MySQL offers s built-in autoscaling for both compute & storage, making it ideal for handling variable workloads.

### Private Database Setup

The Aurora cluster is deployed in database subnets, ensuring that it’s not exposed to the internet. This design significantly reduces the attack surface by restricting access to internal workloads running in private subnets, such as Kubernetes pods. Only authorized resources within the VPC can communicate with the database.

### Storage Encryption with KMS

All data stored in Aurora is encrypted using AWS KMS. This ensures that sensitive information is protected at rest. The KMS key used for encryption is managed centrally, giving us control over key rotation & access policies. Encryption extends to automated backups, snapshots, & replicas, ensuring end-to-end data security.

### IAM Database Authentication

The Aurora cluster is configured with IAM database authentication, which allows us to use IAM roles for database access instead of traditional username/password credentials. This approach is more secure because:

- There’s no need to manage passwords in the application code.
- Access is tied to IAM roles, making it easier to enforce least-privilege policies & revoke access when needed.

### Autoscaling & Read Replicas

Autoscaling is enabled for the Aurora cluster, allowing it to dynamically adjust compute capacity based on traffic. This is particularly important for handling:

- High Traffic Spikes: During peak traffic, read replicas can scale up to handle increased read workloads, preventing bottlenecks.
- Connection Pooling Issues: By adding more read replicas during high traffic, Aurora ensures the application doesn’t hit connection limits, improving response times & user experience.

### Read Replicas

Aurora read replicas are crucial for scaling read-heavy workloads. Traffic can be distributed across replicas using a load balancer or connection pooling strategy. This not only improves performance but also reduces the load on the primary instance, ensuring smooth operation during traffic spikes.

### Secrets Management & Rotation

The Aurora cluster’s master password is managed using AWS Secrets Manager. Secrets Manager automatically rotates the password, ensuring it’s always up-to-date & reducing the risk of credential leaks. By integrating Secrets Manager with Aurora, applications can securely retrieve database credentials without hardcoding them.

Why Automatic Rotation?

- It eliminates manual processes for updating passwords, reducing human error.
- Credentials are updated seamlessly, ensuring minimal disruption to services.

### Snapshots for Backup & Recovery

Snapshots are an integral part of this setup for disaster recovery & data retention. While Aurora automatically performs backups, manual snapshots allow us to:

- Preserve Point-in-Time Data: Snapshots capture the state of the database at a specific time, which is helpful for compliance or testing.
- Disaster Recovery: In case of accidental data loss, snapshots can be used to restore the database quickly.

### Performance Insights

Aurora is configured with Performance Insights, which provides detailed metrics for database performance. This helps in:

- Identifying slow queries or performance bottlenecks.
- Optimizing database configurations & query execution.

How to Setup/Run the Infrastructure & Deploy the App

### Prerequisites

FOr initial setup up tu run our infrastructure, we use Terraform. Here’s what we need to do:

1. Install Terraform
   Download & install Terraform from the official website.
2. Develop Terraform Code
   Write Terraform code for the AWS resources we need.
3. Run Terraform Commands
   Initialize, plan, & apply our Terraform configurations:

```sh
terraform init
terraform plan
terraform apply
```

To speed up development, I use existing AWS Terraform modules.
To check cloud resource deployment, you can see the path in this repo: `iac/deployment/cloud/`

After all main resources we need is provisioned

- [KMS](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/main.tf#L2)
- [S3 tfstate](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/main.tf#L23)
- [Route53](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/main.tf#L23)
- [ACM](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/main.tf#L65)
- [Secret Manager](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/main.tf#L99)
- [VPC](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/main.tf#154)
- [EKS](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/main.tf#229)


ArgoCD

```hcl
module "argocd" {
  source = "../../modules/helm"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
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
}
```

[ArgoCD Vault Plugin (AVP) Pod Identity](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/main.tf#229)

```hcl
module "avp_custom_pod_identity" {
  association_defaults = {
    namespace       = "argocd"
    service_account = "argocd-repo-server"
  }
  source_policy_documents = [data.aws_iam_policy_document.avp_policy.json]
}
```

[Atlantis](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/main.tf#L637)
```hcl
module "atlantis" {
  source = "../../modules/helm"
  repository       = "https://runatlantis.github.io/helm-charts"
  chart            = "atlantis"
  values           = ["${file("manifest/${local.atlantis_standard.Feature}.yaml")}"]
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
}
```

[Atlantis Pod Identity](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/main.tf#L683)
```hcl
module "atlantis_custom_pod_identity" {
  association_defaults = {
    namespace       = local.atlantis_standard.Feature
    service_account = "${local.atlantis_standard.Feature}-sa"
    tags            = { App = local.atlantis_standard.Feature }
  }
  source_policy_documents = [data.aws_iam_policy_document.atlantis_policy.json]
}
```
For implementation detail, click the name.


## Prepare Manifests for Atlantis & ArgoCD

First, we need to set up manifests for Atlantis & ArgoCD. As we treat the atlantis and ArgoCD manfest as template. We can inject secrets from AWS Secret Manager into the Helm charts using the Helm provider & set `helm_sets_sensitive` to install ArgoCD.
Here's the detail of ArgoCD manifest
[atlantis.yaml](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/manifest/argocd.yaml#8)
-  [Setup Github Oauth](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/manifest/argocd.yaml#8)
- [Installing ArgoCD Vault Plugin](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/manifest/argocd.yaml#68). ArgoCD Vault Plugin is crucial to secure our secrets. We'll discuss this in the next section.
- [Setup the ArgoCD Server Ingress](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/manifest/argocd.yaml#107)

- Prepare Atlantis Manifest (iac/deployment/cloud/manifest/atlantis.yaml):
- Create Webhooks with Terraform & GitHub Provider

After installing ArgoCD Server (UI) the internet yet. We need to expose it using ALB Ingress Controller.
But before that we need to install the AWS ALB Controller first. Even we can't reach argocd server UI yet
we can access ArgoCD by creating a port-forward to the ArgoCD Server pod.
```sh
kubectl port-forward svc/argocd-server -n argocd 8080:80
```
We can start creating the ArgoCD Application for 
#### [AWS ALB Controller](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/addons/aws-load-balancer-controller/main.tf#18)
- [Create the AWS ALB Controller Application in ArgoCD](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/addons/aws-load-balancer-controller/main.tf#18)
2. [Prepared the manifest for the AWS ALB Controller](https://github.com/greyhats13/phl-store/blob/main/gitops/charts/addons/aws-load-balancer-controller/values.yaml#18)
3. ArgoCD will sync the changes & deploy the AWS ALB Controller to the EKS cluster.
#### [External-dns](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/addons/aws-load-balancer-controller/main.tf#18)
- [Create the AWS ALB Controller Application in ArgoCD](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/addons/external-dns/main.tf#19)
2. [Prepared the manifest for the AWS ALB Controller](https://github.com/greyhats13/phl-store/blob/main/gitops/charts/addons/external-dns/values.yaml#1)
3. ArgoCD will sync the changes & deploy the External-DNS to the EKS cluster.
#### Later, Karpenter

#### Expose ArgoCD and Atlantis with ALB Ingress Controller
After we install AWS ALB controller and External-DNS, our ingress will be automatically created also the record set in Route53. We can access the ArgoCD and Atlantis UI using the domain name we set in the Route53.
- We can check the annotaton setup of [argoCD Ingress here](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/manifest/argocd.yaml#107)
- We can check the annotaton setup of [Atlantis Ingress here](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/manifest/atlantis.yaml#40)
- Terraform will replace the placeholder with the actual values.


### Self Service Model with Atlantis

Once all components are installed, we can create a self-service model using Atlantis & GitOps. Git is the Single Source of Truth (SSoT), & all changes must go through Git. Here’s how it works:

<p align="center">
  <img src="img/atlantis.png" alt="atlantis">
</p>

When we want to provision, set up, or update infrastructure, just make a pull request in the repository set up by Atlantis. 
- Developer want to provision the new service call `phl-products`. Here's for the [example](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/services/phl-products#1)
- Developer also need to add this part so Atlantis can detect the changes in the directory
```yml
projects:
  - dir: iac/deployment/services/phl-profiles
    apply_requirements: ["mergeable,approved"]
    autoplan:
      when_modified: ["*.tf*"]
```

- The delivery team will create the pull request from their feature branch e.g newservices/DEV-1005 to main/master .
- Atlantis will create the autoplan for the infrastructure changes.
-  The infra or devops team reviews & approves the pull request. Let's say, we require at least two approvals & that the pull request is mergeable.
- After approval, developer can start perform the `atlantis apply` to apply the changes to the infrastructure.
- [atlantis.yaml](https://github.com/greyhats13/phl-store/blob/main/iac/atlantis.yaml#26)
```yml
version: 3
projects:
  - dir: iac/deployment/services/phl-profile
    apply_requirements: ["mergeable,approved"]
    autoplan:
      when_modified: ["*.tf*"]
```

That's how we setup the infrastructure for the new service. The same process can be applied to other services.

Check out an example that's have been done [here](https://github.com/greyhats13/phl-store/pull/36)


This part isn’t CI/CD yet, but it’s about preparing a new service. Before deploying a service on Kubernetes, We need to set up components like repository, database, users, Secrets Manager, ArgoCD Application, S3 bucket (if needed), & API Gateway integrations & routing. Doing this manually can slow things down & increase workload. So, we need a self-service model for creating new services.

With Atlantis, developers can use templates provided by devops to create new services on their own. They just fill in details like database name & access user. Terraform code will automatically add secrets to AWS Secret Manager, create ECR repository, set up ArgoCD Application, & configure API Gateway.



## Deploying Applicationg with GitOps

To deploy our service to EKS, we need CI/CD to speed up getting our app to market. So, we use ArgoCD as our GitOps tool to deploy our service to EKS. We will design our CI/CD pipeline like the picture below.

<p align="center">
  <img src="img/cicd.png" alt="aws">
</p>

In this case, we use a mono repo where Terraform code, GitOps repo (Helm), & services are all stored in one repository. CI/CD triggers can vary for each community or company. Here, we use the Gitflow branching strategy. Okay, let’s continue.

### Preparation
1. Assume we already use Atlantis to provision our services and CI/CD components before deploying our application to EKS cluster
2. We need to prepare our application code including th Dockerfile.
3. We need to prepare the Helm chart for our service.
We can create the helm chart
```sh
helm create phl-products
```
Here’s the [example](https://github.com/greyhats13/phl-store/blob/main/gitops/charts/app/phl-products/values.yaml#26
4. We need to prepare the Github Action workflow for our CI/CD pipeline. We can use the template. Here’s the [example]([profile-ci.yml](https://github.com/greyhats13/phl-store/blob/main/.github/workflows/profile-ci.yml#L1)

From the diagram, there are 5 stages:
1. Check out code
2. Unit Test & Coverage stages (not implemented as planned)
  - Because we only have Docker images, we only see the ./app binary from the zylwin/phl-store:latest image.
  - The ideal step is we run unit tests & check coverage. 
  - GitHub Actions do the unit tests, & the reports are uploaded to artifacts for Sonar analysis. We use SonarQube for code quality & security analysis. 
3. Build & Tagging stages
  - Here, GitHub Actions build Docker images 
  - Tag them with the image SHA based on push events to the master or dev branch.
  - After tagging, the images are pushed to the ECR registry. Authentication is done using GitHub OIDC.
- Deployment with ArgoCD
  - In this step, deployment happens after GitHub Actions have pushed the image tags.
  - ArgoCD clones the repository & uses sed to replace the image tag with the pushed image SHA in the Helm chart.
  - Github action will replace appVersion in Chart.yaml with the new image tag. 
  - ArgoCD then detect the the change & syncs the desired state with the live state in EKS. Ideally, we use canary deployments so we can test the new version before rolling it out to all users by splitting the traffic between the old & new versions, but due to time constraints, we do a rolling update instead.

4. End to End Testing
  - API Testing with Newman
  - We use a Postman collection with pre-request & post-response scripts.
  - Since our endpoint needs Authorization, we generate a Bearer Token by hitting the oauth.phl.blast.co.id endpoint.
  - This endpoint is a custom domain from Cognito, which acts as the authorizer for our AWS API Gateway.
  - After getting the token, we save it to a Postman environment variable.
  - Then, we run the Postman collection with Newman for 5 iterations & a 200ms delay between each.
b. Performance Testing with k6.io
  - We set up performance testing scenarios & develop a k6.js script.
  - Then, we run k6.io with 5 iterations & a 200ms delay between each.
c. Security Testing with OWASP ZAP
  - We perform security testing with OWASP ZAP by preparing the OpenAPI spec of our service.
  - Using the Bearer Token saved in $GITHUB_ENV, we run OWASP ZAP.
  - After all tests, we upload the test reports to an S3 bucket.

Reference: [products-ci.yml](https://github.com/greyhats13/phl-store/blob/main/.github/workflows/products-ci.yml#L1)

# Designing scalable, secure & reliable application


##
There are many ways to secure secrets. We can use AWS Secret Store CSI Driver, External Secret, or ArgoCD Vault Plugin (AVP). Here’s the high-level design:

<p align="center">
  <img src="img/cicd.png" alt="aws">
</p>

## Preparation
We will secure secrets using ArgoCD Vault Plugin (AVP) with AWS Secrets Manager. Here are the steps:
1.	Install ArgoCD & AVP on EKS
- We already installed ArgoCD on our EKS cluster & added the ArgoCD Vault Plugin (AVP).
2.	Set Up IAM Policy for AVP
- To use AVP, ArgoCD repo server needs permission to read secrets from Secrets Manager. First, we create an IAM policy:

[ArgoCD Vault Plugin IAM Policy](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/iam_policies.tf#L27)
```hcl
data "aws_iam_policy_document" "avp_policy" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      "*",
    ]
  }
}
```

**3**	Attach IAM Policy to ArgoCD Repo Server
- Next, we attach this policy to the IAM Role used by argocd-repo-server & associate the IAM Role with the Kubernetes service account.
[ArgoCD Vault Plugin IAM Policy](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/cloud/main.tf#L609)
```hcl
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

**4.**	Create Secret Template for Helm Chart
Now, AVP can read secrets from AWS Secrets Manager. We need to create a secret.yaml template for our Helm chart.
- [secret.yaml](https://github.com/greyhats13/phl-store/blob/main/gitops/charts/app/phl-products/templates/secret.yaml#L27)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}
  namespace: {{ .Release.Namespace }}
  {{- if .Values.appSecret.annotations }}
  annotations:
    {{- toYaml .Values.appSecret.annotations | nindent 4 }}
  {{- end }}
type: Opaque
stringData:
  config.json: |-
    {
    {{- $secretMap := .Values.appSecret.secrets }}
    {{- $count := len $secretMap }}
    {{- $i := 0 }}
    {{- range $key, $val := $secretMap }}
      "{{ $key }}": "{{ $val }}"{{- if lt (add1 $i) $count }},{{ end }}
      {{- $i = add1 $i }}
    {{- end }}
    }
```
In this manifest, we allow values.yaml to accept appSecret annotation. Our service phl-products reads secrets from file, so we need to create stringData & convert key-value secrets from Secrets Manager into JSON.

```yaml
stringData:
  config.json: |-
    {
    {{- $secretMap := .Values.appSecret.secrets }}
    {{- $count := len $secretMap }}
    {{- $i := 0 }}
    {{- range $key, $val := $secretMap }}
      "{{ $key }}": "{{ $val }}"{{- if lt (add1 $i) $count }},{{ end }}
      {{- $i = add1 $i }}
    {{- end }}
    }
```
5.	Prepare Secret Annotations in values.yaml
We also need to set up secret annotations in values.yaml to tell AVP where to find the secrets.
```yaml
appSecret:
  annotations:
    avp.kubernetes.io/path: "phl/svc/phl-products"
    avp.kubernetes.io/secret-version: "AWSCURRENT"
  secrets:
    connection_string: <connection_string>
    port: <port>
```

```yaml
    avp.kubernetes.io/path: This is the name of our secret in AWS.
    avp.kubernetes.io/secret-version: This is the latest version of our secret.
```

6. Mount Secrets in Deployment
Now, we need to mount the secrets in our deployment manifest as /config/config.json
We use the secret created by AVP in the Helm chart.
- [Volume Mount](https://github.com/greyhats13/phl-store/blob/main/gitops/charts/app/phl-products/values.yaml#135)
```yaml
 Additional volumes on the output Deployment definition.
volumes:
  - name: config-volume
    secret:
      secretName: phl-dev-svc-products
      items:
        - key: config.json
          path: config.json

# Additional volumeMounts on the output Deployment definition.
volumeMounts:
  - name: config-volume
    mountPath: "/config/config.json"
    subPath: config.json
```

7. Replace Placeholders with Secrets
When ArgoCD syncs, it replaces the placeholders with values from Secrets Manager.
- [secret.yaml](https://github.com/greyhats13/phl-store/blob/main/gitops/charts/app/phl-products/templates/secret.yaml#L27)
```yaml
```yaml
appSecret:
  annotations:
    avp.kubernetes.io/path: "phl/svc/phl-products"
    avp.kubernetes.io/secret-version: "AWSCURRENT"
  secrets:
    connection_string: <connection_string>
    port: <port>
```

### Use Distroless Image for Security
To make our application more secure, we can use a distroless image for our service. It can reduce the attack surface, minimized vulnerabilities, and improved the prformance. Also This way, no one can access secrets from the container.
- [Dockerfile](https://github.com/greyhats13/phl-store/blob/main/services/phl-products/templates/Dockerfile-distrolessl#L27)
```Dockerfile
# Use a minimal base image for distroless
FROM gcr.io/distroless/static:nonroot

COPY /usr/share/zoneinfo /usr/share/zoneinfo

# Copy the binary into the image
COPY ./app /build/app

EXPOSE 8080

# Run the binary
CMD ["/build/app"]
```

### Implement HPA for  Pod Autoscaling and Karpenter for Node Autoscaling
we need to set up the metrics server in our EKS cluster first before stepping up the HPA.
To make our application more scalable, we can use Horizontal Pod Autoscaler (HPA) in Kubernetes. HPA automatically scales the number of pods based on CPU/Memoery utilization or custom metrics. Here’s how we set up HPA for our service:
- [HPA Configuration](https://github.com/greyhats13/phl-store/blob/main/gitops/charts/app/phl-products/values.yaml#135)
```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 20
  targetCPUUtilizationPercentage: 75
  targetMemoryUtilizationPercentage: 75
```
We also have implement Karpenter for Node autoscalin to scale out the nodes as the pod increase so does the node. This way, we can handle traffic spikes & ensure our application is always available. It can scale in as well when the traffic is low.

### Increase Pod Security
- [values.yaml](https://github.com/greyhats13/phl-store/blob/main/gitops/charts/app/phl-products/values.yaml#135)
We can remove all the linux capabilities from the pod, run the pod as a non-root user, & set the user ID to 1000. We can also set the pod to read-only root filesystem & disallow privilege escalation. Prevents attackers from modifying the filesystem if they gain access, enhancing the container integrity. Here’s how we configure the pod security context:
```yaml
podSecurityContext:
  fsGroup: 2000
  runAsNonRoot: true
  # Optional: If your application requires specific supplemental groups
  supplementalGroups:
    - 1001
    - 1002

securityContext:
  capabilities:
    drop:
      - ALL
    add:
      - NET_BIND_SERVICE  # Example: Allow binding to ports below 1024 if necessary
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  # Optional: SELinux options
  seLinuxOptions:
    level: "s0:c123,c456"
  ```

### Use API Gateway for Security & Rate Limiting
To secure our APIs, we can use AWS API Gateway that we've created. It acts as a front door for our services, providing authentication, authorization, & rate limiting. We can set up API Gateway to require API keys, use AWS Cognito for user authentication, & integrate with AWS WAF for web application firewall protection. Here’s how we can configure API Gateway for our service:
- [API Gateway Configuration](https://github.com/greyhats13/phl-store/blob/main/iac/deployment/services/phl-products/main.yaml#184)
We can also implement WAF rules to protect our APIs from common web exploits like SQL injection & cross-site scripting. This way, we can ensure our APIs are secure & reliable. As AWS API Gateway HTTP API doesnt support WAF, we can use AWS WAF with ALB to protect our APIs.

### Provide API Testing, Performance Testing, & Security Testing
To ensure our application is reliable & secure, we need to perform API testing, performance testing, & security testing. 
API testing will check if our APIs are working as expected. We can use Postman & Newman to run API tests. We can also use k6.io for performance testing to check how our application performs under load. For security testing, we can use OWASP ZAP to find vulnerabilities in our application. Here’s how we can set up these tests:
- [end_to_end_test](https://github.com/greyhats13/phl-store/blob/main/.github/workflows/products-ci.yml#L04)


### Use  Redis for Caching
To improve the performance of our application, we can use Redis for caching such as Amazon Elasticache. Redis is an in-memory data store that can help reduce latency & speed up response times. We can cache frequently accessed data in Redis, so our application doesn’t have to fetch it from the database every time. This way, we can improve the performance of our application &  a better user experience.provide. Current binary app has no implementation for Redis caching yet.