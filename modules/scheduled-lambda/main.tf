locals {
  tags = merge({ managed_by = "lambdacron" }, var.tags)
  environment_variables = merge(
    { SNS_TOPIC_ARN = var.sns_topic_arn },
    var.lambda_env,
  )
  lambda_name = coalesce(var.lambda_name, "lambdacron-scheduled-${terraform.workspace}")
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    sid       = "AllowCloudWatchLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    sid       = "AllowSnsPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.sns_topic_arn]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${local.lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "${local.lambda_name}-permissions"
  policy = data.aws_iam_policy_document.lambda_permissions.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "scheduled" {
  function_name = local.lambda_name
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = var.lambda_image_uri
  timeout       = var.timeout
  memory_size   = var.memory_size

  dynamic "image_config" {
    for_each = length(coalesce(var.image_command, [])) > 0 ? [1] : []

    content {
      command = var.image_command
    }
  }

  environment {
    variables = local.environment_variables
  }

  tags = local.tags
}

resource "aws_lambda_function_url" "test" {
  count              = var.create_test_url ? 1 : 0
  function_name      = aws_lambda_function.scheduled.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "allow_function_url" {
  count                  = var.create_test_url ? 1 : 0
  statement_id           = "AllowFunctionUrlInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.scheduled.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "allow_function_url_invoke" {
  count         = var.create_test_url ? 1 : 0
  statement_id  = "AllowFunctionUrlInvokeFunction"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled.function_name
  principal     = "*"
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${aws_lambda_function.scheduled.function_name}-schedule"
  schedule_expression = var.schedule_expression
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "scheduled-lambda"
  arn       = aws_lambda_function.scheduled.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}
