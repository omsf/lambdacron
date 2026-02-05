locals {
  tags        = merge({ managed_by = "cloudcron" }, var.tags)
  lambda_name = coalesce(var.lambda_name, "cloudcron-email-${terraform.workspace}")
  base_env = {
    (var.subject_template_env_var) = file(var.subject_template_file)
    (var.text_template_env_var)    = file(var.text_template_file)
    (var.html_template_env_var)    = file(var.html_template_file)
    EMAIL_SENDER                   = var.sender
    EMAIL_RECIPIENTS               = jsonencode(var.recipients)
  }
  optional_env = merge(
    length(var.reply_to) > 0 ? { EMAIL_REPLY_TO = jsonencode(var.reply_to) } : {},
  )
  env_vars = merge(local.base_env, local.optional_env)
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda_role" {
  name = "${local.lambda_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = local.tags
}

module "plumbing" {
  source = "../notification-plumbing"

  sns_topic_arn       = var.sns_topic_arn
  lambda_function_arn = aws_lambda_function.email.arn
  result_types        = var.result_types
  fifo_queue_name     = var.fifo_queue_name
  batch_size          = var.batch_size
  enabled             = var.enabled
  tags                = local.tags
}

resource "aws_iam_policy" "lambda_logs_policy" {
  name = "${local.lambda_name}-logs"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"
      },
    ]
  })
  tags = local.tags
}

resource "aws_iam_policy" "lambda_ses_policy" {
  name = "${local.lambda_name}-ses"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ses:FromAddress" = var.sender
          }
        }
      },
    ]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_logs_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_ses_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_ses_policy.arn
}

resource "aws_lambda_function" "email" {
  function_name = local.lambda_name
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = var.lambda_image_uri
  timeout       = var.timeout
  memory_size   = var.memory_size

  image_config {
    command = ["lambda.email_handler"]
  }

  environment {
    variables = local.env_vars
  }

  tags = local.tags
}

resource "aws_iam_policy" "lambda_sqs_policy" {
  name   = "${local.lambda_name}-sqs"
  policy = module.plumbing.lambda_sqs_policy_json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}
