data "aws_caller_identity" "current" {}

locals {
  tags = merge({ managed_by = "lambdacron" }, var.tags)

  account_id        = data.aws_caller_identity.current.account_id
  resource_prefixes = [for prefix in var.allowed_resource_name_prefixes : trimspace(prefix)]

  iam_role_arns = [
    for prefix in local.resource_prefixes : "arn:aws:iam::${local.account_id}:role/${prefix}*"
  ]
  iam_policy_arns = [
    for prefix in local.resource_prefixes : "arn:aws:iam::${local.account_id}:policy/${prefix}*"
  ]
  lambda_function_arns = [
    for prefix in local.resource_prefixes : "arn:aws:lambda:*:${local.account_id}:function:${prefix}*"
  ]
  eventbridge_rule_arns = [
    for prefix in local.resource_prefixes : "arn:aws:events:*:${local.account_id}:rule/${prefix}*"
  ]
  sns_topic_arns = [
    for prefix in local.resource_prefixes : "arn:aws:sns:*:${local.account_id}:${prefix}*"
  ]
  sns_subscription_arns = [
    for prefix in local.resource_prefixes : "arn:aws:sns:*:${local.account_id}:${prefix}*"
  ]
  sqs_queue_arns = [
    for prefix in local.resource_prefixes : "arn:aws:sqs:*:${local.account_id}:${prefix}*"
  ]
  ecr_private_repository_arns = [
    for prefix in local.resource_prefixes : "arn:aws:ecr:*:${local.account_id}:repository/${prefix}*"
  ]
  ecr_public_repository_arns = [
    for prefix in local.resource_prefixes : "arn:aws:ecr-public::${local.account_id}:repository/${prefix}*"
  ]

  lambda_iam_statements = [
    {
      sid = "IamRoleManagement"
      actions = [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:ListRolePolicies",
        "iam:ListRoleTags",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:UpdateAssumeRolePolicy",
      ]
      resources = local.iam_role_arns
    },
    {
      sid = "IamManagedPolicyManagement"
      actions = [
        "iam:CreatePolicy",
        "iam:CreatePolicyVersion",
        "iam:DeletePolicy",
        "iam:DeletePolicyVersion",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicyVersions",
        "iam:TagPolicy",
        "iam:UntagPolicy",
      ]
      resources = local.iam_policy_arns
    },
    {
      sid = "IamRoleManagedPolicyAttachment"
      actions = [
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
      ]
      resources = local.iam_role_arns
      conditions = [
        {
          test     = "ArnLike"
          variable = "iam:PolicyARN"
          values   = local.iam_policy_arns
        },
      ]
    },
    {
      sid = "IamRoleAttachedPolicyRead"
      actions = [
        "iam:ListAttachedRolePolicies",
      ]
      resources = local.iam_role_arns
    },
    {
      sid = "IamPassRoleToLambda"
      actions = [
        "iam:PassRole",
      ]
      resources = local.iam_role_arns
      conditions = [
        {
          test     = "StringEquals"
          variable = "iam:PassedToService"
          values   = ["lambda.amazonaws.com"]
        },
      ]
    },
    {
      sid = "LambdaFunctionManagement"
      actions = [
        "lambda:AddPermission",
        "lambda:CreateFunction",
        "lambda:CreateFunctionUrlConfig",
        "lambda:DeleteFunction",
        "lambda:DeleteFunctionUrlConfig",
        "lambda:GetFunction",
        "lambda:GetFunctionConfiguration",
        "lambda:GetFunctionUrlConfig",
        "lambda:GetPolicy",
        "lambda:ListVersionsByFunction",
        "lambda:ListTags",
        "lambda:RemovePermission",
        "lambda:TagResource",
        "lambda:UntagResource",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:UpdateFunctionUrlConfig",
      ]
      resources = local.lambda_function_arns
    },
  ]

  eventbridge_schedule_statements = [
    {
      sid = "EventBridgeScheduleManagement"
      actions = [
        "events:DeleteRule",
        "events:DescribeRule",
        "events:ListTagsForResource",
        "events:ListTargetsByRule",
        "events:PutRule",
        "events:PutTargets",
        "events:RemoveTargets",
        "events:TagResource",
        "events:UntagResource",
      ]
      resources = local.eventbridge_rule_arns
    },
  ]

  scheduled_lambda_ecr_statements = [
    {
      sid = "EcrImageReadForLambdaCreateUpdate"
      actions = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      ]
      resources = local.ecr_private_repository_arns
    },
    {
      sid = "EcrRepositoryPolicyReadWriteForLambdaCreateUpdate"
      actions = [
        "ecr:GetRepositoryPolicy",
        "ecr:SetRepositoryPolicy",
      ]
      resources = local.ecr_private_repository_arns
    },
  ]

  root_sns_topic_statements = [
    {
      sid = "SnsTopicCreate"
      actions = [
        "sns:CreateTopic",
      ]
      resources = ["*"]
    },
    {
      sid = "SnsTopicManagement"
      actions = [
        "sns:DeleteTopic",
        "sns:GetTopicAttributes",
        "sns:ListTagsForResource",
        "sns:SetTopicAttributes",
        "sns:TagResource",
        "sns:UntagResource",
      ]
      resources = local.sns_topic_arns
    },
  ]

  notification_plumbing_statements = [
    {
      sid = "SqsQueueCreate"
      actions = [
        "sqs:CreateQueue",
      ]
      resources = ["*"]
    },
    {
      sid = "SqsQueueManagement"
      actions = [
        "sqs:DeleteQueue",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ListQueueTags",
        "sqs:SetQueueAttributes",
        "sqs:TagQueue",
        "sqs:UntagQueue",
      ]
      resources = local.sqs_queue_arns
    },
    {
      sid = "SnsSubscriptionCreate"
      actions = [
        "sns:Subscribe",
      ]
      resources = local.sns_topic_arns
    },
    {
      sid = "SnsSubscriptionManagement"
      actions = [
        "sns:GetSubscriptionAttributes",
        "sns:SetSubscriptionAttributes",
        "sns:Unsubscribe",
      ]
      resources = local.sns_subscription_arns
    },
    {
      sid = "LambdaEventSourceMappingManagement"
      actions = [
        "lambda:CreateEventSourceMapping",
        "lambda:DeleteEventSourceMapping",
        "lambda:GetEventSourceMapping",
        "lambda:ListEventSourceMappings",
        "lambda:UpdateEventSourceMapping",
      ]
      resources = ["*"]
    },
  ]

  ecr_private_repository_management_statements = [
    {
      sid = "EcrPrivateRepositoryCreate"
      actions = [
        "ecr:CreateRepository",
      ]
      resources = ["*"]
    },
    {
      sid = "EcrPrivateRepositoryManagement"
      actions = [
        "ecr:DeleteRepository",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:GetLifecyclePolicy",
        "ecr:ListTagsForResource",
        "ecr:PutLifecyclePolicy",
        "ecr:TagResource",
        "ecr:UntagResource",
      ]
      resources = local.ecr_private_repository_arns
    },
  ]

  ecr_private_push_statements = [
    {
      sid = "EcrPrivateAuthorization"
      actions = [
        "ecr:GetAuthorizationToken",
      ]
      resources = ["*"]
    },
    {
      sid = "EcrPrivatePushPull"
      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
      ]
      resources = local.ecr_private_repository_arns
    },
  ]

  ecr_private_repository_policy_statements = [
    {
      sid = "EcrPrivateRepositoryPolicyManagement"
      actions = [
        "ecr:DeleteRepositoryPolicy",
        "ecr:GetRepositoryPolicy",
        "ecr:SetRepositoryPolicy",
      ]
      resources = local.ecr_private_repository_arns
    },
  ]

  ecr_public_authentication_statements = [
    {
      sid = "EcrPublicAuthentication"
      actions = [
        "ecr-public:GetAuthorizationToken",
        "sts:GetServiceBearerToken",
      ]
      resources = ["*"]
    },
  ]

  ecr_public_read_statements = [
    {
      sid = "EcrPublicRead"
      actions = [
        "ecr-public:BatchGetImage",
        "ecr-public:DescribeImages",
        "ecr-public:GetDownloadUrlForLayer",
      ]
      resources = local.ecr_public_repository_arns
    },
  ]

  ecr_public_repository_management_statements = [
    {
      sid = "EcrPublicRepositoryCreate"
      actions = [
        "ecr-public:CreateRepository",
      ]
      resources = ["*"]
    },
    {
      sid = "EcrPublicRepositoryManagement"
      actions = [
        "ecr-public:DeleteRepository",
        "ecr-public:DescribeRepositories",
        "ecr-public:GetRepositoryCatalogData",
        "ecr-public:PutRepositoryCatalogData",
        "ecr-public:TagResource",
        "ecr-public:UntagResource",
      ]
      resources = local.ecr_public_repository_arns
    },
  ]

  ecr_public_push_statements = [
    {
      sid = "EcrPublicPush"
      actions = [
        "ecr-public:BatchCheckLayerAvailability",
        "ecr-public:CompleteLayerUpload",
        "ecr-public:InitiateLayerUpload",
        "ecr-public:PutImage",
        "ecr-public:UploadLayerPart",
      ]
      resources = local.ecr_public_repository_arns
    },
  ]

  scheduled_lambda_statements = concat(
    local.lambda_iam_statements,
    local.eventbridge_schedule_statements,
    local.scheduled_lambda_ecr_statements,
  )
  notification_channel_statements = concat(local.lambda_iam_statements, local.notification_plumbing_statements)
  lambda_image_build_statements = concat(
    local.ecr_private_repository_management_statements,
    local.ecr_private_push_statements,
    local.ecr_private_repository_policy_statements,
  )
  lambda_image_republish_statements = concat(
    local.lambda_image_build_statements,
    local.ecr_public_authentication_statements,
    local.ecr_public_read_statements,
  )
  lambda_image_public_statements = concat(
    local.ecr_public_repository_management_statements,
    local.ecr_public_authentication_statements,
    local.ecr_public_read_statements,
    local.ecr_public_push_statements,
  )
  root_module_statements = concat(local.scheduled_lambda_statements, local.root_sns_topic_statements)

  permission_set_catalog = {
    "scheduled-lambda" = {
      description = "Deploy the scheduled Lambda module (Lambda + IAM + EventBridge schedule wiring + ECR image lookup/repository policy permissions for image-based create/update)."
      statements  = local.scheduled_lambda_statements
    }
    "notification-plumbing" = {
      description = "Deploy SNS subscription + SQS queue + Lambda event source mapping plumbing."
      statements  = local.notification_plumbing_statements
    }
    "print-notification" = {
      description = "Deploy print notification module permissions (notification-plumbing + Lambda/IAM role wiring)."
      statements  = local.notification_channel_statements
    }
    "email-notification" = {
      description = "Deploy email notification module permissions (notification-plumbing + Lambda/IAM role wiring)."
      statements  = local.notification_channel_statements
    }
    "sms-notification" = {
      description = "Deploy SMS notification module permissions (notification-plumbing + Lambda/IAM role wiring)."
      statements  = local.notification_channel_statements
    }
    "lambda-image-build" = {
      description = "Deploy private ECR image build module permissions (repository + repository policy management + image push)."
      statements  = local.lambda_image_build_statements
    }
    "lambda-image-republish" = {
      description = "Deploy private ECR image republish module permissions (build set + public ECR auth/read)."
      statements  = local.lambda_image_republish_statements
    }
    "lambda-image-public" = {
      description = "Deploy public ECR image publishing module permissions."
      statements  = local.lambda_image_public_statements
    }
    "root" = {
      description = "Deploy root module permissions (scheduled-lambda set + shared SNS topic management)."
      statements  = local.root_module_statements
    }
  }

  unknown_permission_sets = setsubtract(var.permission_sets, toset(keys(local.permission_set_catalog)))

  selected_permission_sets = {
    for permission_set in var.permission_sets : permission_set => local.permission_set_catalog[permission_set]
    if contains(keys(local.permission_set_catalog), permission_set)
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "GitHubActionsAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = [var.github_audience]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = sort(var.github_subjects)
    }

    dynamic "condition" {
      for_each = length(var.github_job_workflow_refs) == 0 ? [] : [1]

      content {
        test     = "StringLike"
        variable = "token.actions.githubusercontent.com:job_workflow_ref"
        values   = sort(var.github_job_workflow_refs)
      }
    }
  }
}

resource "aws_iam_role" "deployer" {
  name                 = var.role_name
  description          = var.role_description
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  max_session_duration = var.max_session_duration
  tags                 = local.tags

  lifecycle {
    precondition {
      condition     = length(local.unknown_permission_sets) == 0
      error_message = "Unknown permission sets: ${join(", ", sort(tolist(local.unknown_permission_sets)))}. Valid names are: ${join(", ", sort(keys(local.permission_set_catalog)))}."
    }
  }
}

data "aws_iam_policy_document" "permission_set" {
  for_each = local.selected_permission_sets

  dynamic "statement" {
    for_each = each.value.statements

    content {
      sid       = statement.value.sid
      effect    = "Allow"
      actions   = statement.value.actions
      resources = statement.value.resources

      dynamic "condition" {
        for_each = try(statement.value.conditions, [])

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_policy" "permission_set" {
  for_each = data.aws_iam_policy_document.permission_set

  name        = substr("${var.role_name}-${each.key}", 0, 128)
  description = "LambdaCron deployer permission set ${each.key}."
  policy      = each.value.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "permission_set" {
  for_each = aws_iam_policy.permission_set

  role       = aws_iam_role.deployer.name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.additional_policy_arns)

  role       = aws_iam_role.deployer.name
  policy_arn = each.value
}
