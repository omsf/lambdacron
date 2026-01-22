locals {
  tags = merge({ managed_by = "cloudcron" }, var.tags)
}

resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name                        = replace(var.fifo_queue_name, ".fifo", "-dlq.fifo")
  fifo_queue                  = true
  content_based_deduplication = var.content_based_deduplication
  message_retention_seconds   = var.message_retention_seconds
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  tags                        = local.tags
}

resource "aws_sqs_queue" "queue" {
  name                        = var.fifo_queue_name
  fifo_queue                  = true
  content_based_deduplication = var.content_based_deduplication
  message_retention_seconds   = var.message_retention_seconds
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  tags                        = local.tags

  redrive_policy = var.create_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null
}

resource "aws_sqs_queue_policy" "allow_sns" {
  queue_url = aws_sqs_queue.queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSnsPublish"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = var.sns_topic_arn
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "queue" {
  topic_arn = var.sns_topic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.queue.arn

  raw_message_delivery = true
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.queue.arn
  function_name    = var.lambda_function_arn
  enabled          = var.enabled
  batch_size       = var.batch_size
}

data "aws_iam_policy_document" "lambda_sqs_access" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
    ]
    resources = [aws_sqs_queue.queue.arn]
  }
}
