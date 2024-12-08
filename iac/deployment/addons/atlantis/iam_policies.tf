# ArgoCD Vault Plugin IAM Policy
data "aws_iam_policy_document" "atlantis_policy" {
  # allow get secret value
  statement {
    actions = [
      "*",
    ]

    resources = [
      "*",
    ]
  }
}