output "queue_arn" {
  description = "ARN of the notification SQS queue."
  value       = aws_sqs_queue.queue.arn
}

output "queue_url" {
  description = "URL of the notification SQS queue."
  value       = aws_sqs_queue.queue.id
}

output "queue_name" {
  description = "Name of the notification SQS queue."
  value       = aws_sqs_queue.queue.name
}

output "dlq_arn" {
  description = "ARN of the dead-letter queue (if created)."
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "subscription_arn" {
  description = "ARN of the SNS subscription."
  value       = aws_sns_topic_subscription.queue.arn
}

output "event_source_mapping_uuid" {
  description = "UUID of the Lambda event source mapping."
  value       = aws_lambda_event_source_mapping.sqs.uuid
}

output "lambda_sqs_policy_json" {
  description = "IAM policy JSON granting Lambda access to the SQS queue."
  value       = data.aws_iam_policy_document.lambda_sqs_access.json
}
