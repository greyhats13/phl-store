# Service IAM Policy
data "aws_iam_policy_document" "svc_policy" {
  # allow get secret value
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      "*",
    ]
  }
}
