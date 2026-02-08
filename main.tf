locals {
  tags = merge({ managed_by = "cloudcron" }, var.tags)
}

resource "aws_sns_topic" "results" {
  name = var.topic_name

  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : null

  tags = local.tags

  lifecycle {
    precondition {
      condition     = !var.fifo_topic || can(regex("\\.fifo$", var.topic_name))
      error_message = "When fifo_topic is true, topic_name must end with .fifo."
    }
  }
}

module "scheduled_lambda" {
  source = "./modules/scheduled-lambda"

  lambda_image_uri    = var.lambda_image_uri
  schedule_expression = var.schedule_expression
  sns_topic_arn       = aws_sns_topic.results.arn

  lambda_env      = var.lambda_env
  timeout         = var.timeout
  memory_size     = var.memory_size
  lambda_name     = var.lambda_name
  image_command   = var.image_command
  create_test_url = var.create_test_url

  tags = local.tags
}
