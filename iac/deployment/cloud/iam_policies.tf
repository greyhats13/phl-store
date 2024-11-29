# Bucket Policy
data "aws_iam_policy_document" "custom_bucket_policy" {
  statement {
    sid = "AllowUserIacAccessToBucket"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/iac",
      ]
    }

    actions = [
      "s3:GetObject",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      module.bucket_tfstate.s3_bucket_arn,
      "${module.bucket_tfstate.s3_bucket_arn}/*"
    ]
  }
}
