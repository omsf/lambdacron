locals {
  tags        = merge({ managed_by = "cloudcron" }, var.tags)
  lambda_name = coalesce(var.lambda_name, "cloudcron-print-${terraform.workspace}")
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
  lambda_function_arn = aws_lambda_function.print.arn
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

resource "aws_iam_role_policy_attachment" "lambda_logs_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logs_policy.arn
}

resource "aws_lambda_function" "print" {
  function_name = local.lambda_name
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = var.lambda_image_uri
  timeout       = var.timeout
  memory_size   = var.memory_size

  environment {
    variables = {
      (var.template_env_var) = file(var.template_file)
    }
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
