locals {
  tags                    = merge({ managed_by = "lambdacron" }, var.tags)
  tf_state_bucket_arn     = "arn:aws:s3:::${var.state_bucket}"
  tf_state_object_arn     = "${local.tf_state_bucket_arn}/*"
  lock_table_region       = coalesce(var.aws_region, data.aws_region.current.name)
  github_repository_parts = split("/", var.github_repository)
  github_repository_owner = local.github_repository_parts[0]
  github_repository_name  = local.github_repository_parts[1]
  backend_actions_secrets = merge(
    { TF_STATE_BUCKET = var.state_bucket },
    var.locks_table == null ? {} : { TF_STATE_TABLE = var.locks_table },
  )
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "github_repository" "provider_context" {
  name = local.github_repository_name
}

check "github_provider_owner_matches_repository_owner" {
  assert {
    condition     = data.github_repository.provider_context.full_name == var.github_repository
    error_message = "GitHub provider owner mismatch: expected \"${var.github_repository}\" from repository name \"${local.github_repository_name}\", but provider resolved \"${data.github_repository.provider_context.full_name}\". Configure provider \"github\" with owner = \"${local.github_repository_owner}\"."
  }
}

data "aws_iam_policy_document" "terraform_backend_access" {
  statement {
    sid = "TerraformStateBucketAccess"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [local.tf_state_bucket_arn]
  }

  statement {
    sid = "TerraformStateObjectAccess"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [local.tf_state_object_arn]
  }

  dynamic "statement" {
    for_each = var.locks_table == null ? [] : [var.locks_table]
    content {
      sid = "TerraformLockTableAccess"
      actions = [
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
      ]
      resources = ["arn:aws:dynamodb:${local.lock_table_region}:${data.aws_caller_identity.current.account_id}:table/${statement.value}"]
    }
  }
}

resource "aws_iam_policy" "terraform_backend_access" {
  name_prefix = "lambdacron-tf-backend-access-"
  description = "Allow Terraform/OpenTofu backend access to S3 state and DynamoDB locks."
  policy      = data.aws_iam_policy_document.terraform_backend_access.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "terraform_backend_access" {
  role       = var.role_name
  policy_arn = aws_iam_policy.terraform_backend_access.arn
}

resource "github_actions_secret" "backend" {
  for_each = local.backend_actions_secrets

  repository      = local.github_repository_name
  secret_name     = each.key
  plaintext_value = each.value
}
