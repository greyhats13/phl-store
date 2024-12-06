# GitHub Repository Terraform Module

This Terraform module provisions GitHub repositories along with features like branch protection, webhooks, security and analysis configurations, and deploy keys. It's designed to help streamline the creation and management of GitHub repositories using Infrastructure as Code (IaC) principles.

## Features

- **Repository Creation**: Create GitHub repositories with various configurable settings such as visibility, issues, discussions, and more.
- **Branch Protection**: Manage branch protection rules, including required status checks and pull request reviews.
- **Webhooks**: Set up webhooks to trigger external services like CI/CD systems.
- **Deploy Keys**: Add deploy keys to the repository for read or write access using SSH.
- **Security & Analysis**: Enable security features such as vulnerability alerts and secret scanning.
- **Kubernetes Integration**: Optionally integrate with Kubernetes by creating secrets for ArgoCD.
- **GitHub Actions Secrets**: Manage secrets used in GitHub Actions for CI/CD pipelines.

## Usage

Here is an example of how to use this module to create a repository with specific configurations:

```hcl
locals {
    iac_secrets_map = jsondecode(module.gsm_iac.secret_version_data)
    repo_iac_standard = {
      Unit    = var.unit
      Env     = var.env
      Code    = "repo"
      Feature = "iac"
    }
}
module "repo_iac" {
  source                 = "../../modules/cicd/github_repo"
  standard               = local.repo_iac_standard
  visibility             = "public"
  has_issues             = true
  has_discussions        = true
  has_projects           = true
  has_wiki               = true
  delete_branch_on_merge = true
  auto_init              = false
  gitignore_template     = "Terraform"
  security_and_analysis = {
    advanced_security = {
      status = "enabled"
    }
    secret_scanning = {
      status = "enabled"
    }
    secret_scanning_push_protection = {
      status = "enabled"
    }
  }
  topics               = ["terraform","ansible", "iac", "devops", "gcp", "argocd", "kubernetes"]
  vulnerability_alerts = true
  webhooks = {
    atlantis = {
      configuration = {
        url          = "https://atlantis.fta.blast.co.id/events"
        content_type = "json"
        insecure_ssl = false
        secret       = local.iac_secrets_map["github_webhook_atlantis"]
      }
      active = true
      events = ["push", "pull_request", "pull_request_review", "issue_comment"]
    }
  }
}
```

## Inputs

| Name                                | Description                                                                                   | Type           | Default  | Required |
|-------------------------------------|-----------------------------------------------------------------------------------------------|----------------|----------|:--------:|
| `standard`                          | A map containing standard naming convention variables for resources.                          | `map(string)`  | n/a      |   yes    |
| `visibility`                        | The visibility of the repository. Can be `public` or `private`.                               | `string`       | n/a      |   yes    |
| `has_issues`                        | Enable GitHub Issues features on the repository.                                               | `bool`         | `false`  |    no    |
| `has_discussions`                   | Enable GitHub Discussions features on the repository.                                          | `bool`         | `false`  |    no    |
| `has_projects`                      | Enable GitHub Projects features on the repository.                                             | `bool`         | `false`  |    no    |
| `has_wiki`                          | Enable GitHub Wiki features on the repository.                                                 | `bool`         | `false`  |    no    |
| `delete_branch_on_merge`            | Automatically delete head branches when pull requests are merged.                              | `bool`         | `false`  |    no    |
| `auto_init`                         | Produce an initial commit in the repository.                                                   | `bool`         | `false`  |    no    |
| `gitignore_template`                | Name of the GitHub `.gitignore` template to use (e.g., "Terraform").                           | `string`       | `null`   |    no    |
| `security_and_analysis`             | Configuration for GitHub Security and Analysis features.                                       | `object`       | `null`   |    no    |
| `topics`                            | List of topics to apply to the repository.                                                     | `list(string)` | `[]`     |    no    |
| `vulnerability_alerts`              | Enable vulnerability alerts for the repository.                                                | `bool`         | `false`  |    no    |
| `webhooks`                          | Map of webhooks to be added to the repository.                                                 | `map(object)`  | `{}`     |    no    |
| `teams_permission`                  | List of teams permission to be added to the repository.                                        | `map(string)`  | `{}`     |    no    |
| `argocd_namespace`                  | ArgoCD namespace where Kubernetes secrets will be created.                                     | `string`       | `null`   |    no    |
| `github_action_secrets`             | Map of secrets to be added to GitHub Actions environments.                                     | `map(string)`  | `{}`     |    no    |

## Outputs

| Name                         | Description                                                  |
|------------------------------|--------------------------------------------------------------|
| `full_name`                  | Full name of the repository in the format `orgname/reponame`. |
| `name`                       | Name of the repository.                                      |
| `html_url`                   | URL to the repository on the web.                            |
| `ssh_clone_url`              | URL for SSH cloning the repository.                          |
| `http_clone_url`             | URL for HTTPS cloning the repository.                        |
| `git_clone_url`              | URL for anonymous cloning via the Git protocol.              |
| `svn_url`                    | URL for SVN checkout via GitHub's Subversion protocol.       |
| `node_id`                    | GraphQL global node ID for use with GitHub v4 API.           |
| `repo_id`                    | GitHub ID of the repository.                                 |
| `primary_language`           | The primary language of the repository.                      |
| `pages`                      | GitHub Pages configuration for the repository.               |

## Example

```hcl
module "repo_iac" {
  source                 = "../../modules/cicd/github_repo"
  standard               = {
    Unit    = "ols"
    Env     = "dev"
    Code    = "repo"
    Feature = "iac"
  }
  visibility             = "private"
  has_issues             = true
  has_discussions        = true
  delete_branch_on_merge = true
  auto_init              = true
  gitignore_template     = "Terraform"
  topics                 = ["terraform", "devops"]
  vulnerability_alerts   = true
  webhooks = {
    ci = {
      configuration = {
        url          = "https://ci.example.com/webhooks"
        content_type = "json"
        insecure_ssl = false
        secret       = "my-secret-token"
      }
      active = true
      events = ["push", "pull_request"]
    }
  }
}
```

## Resources Created

- **GitHub Repository**: Creates a GitHub repository with the specified configurations.
- **Branch Protection**: Configures branch protection rules for the repository.
- **Webhooks**: Sets up GitHub webhooks to trigger external services.
- **Deploy Keys**: Adds SSH deploy keys to the repository.
- **GitHub Actions Secrets**: Adds secrets for GitHub Actions workflows.

## Requirements

- Terraform version >= 0.13
- GitHub Provider plugin for Terraform

## Notes

- Be sure to grant your Terraform user the necessary permissions to create and manage repositories.
- The `webhooks` block supports multiple webhooks, allowing integration with services like Jenkins, GitLab CI, or Atlantis.
- You can enable security features such as `secret_scanning` and `vulnerability_alerts` to improve repository security.

## Author

- **Imam Arief Rahman** - [greyhats13](https://github.com/greyhats13) 