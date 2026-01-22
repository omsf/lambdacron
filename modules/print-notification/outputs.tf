output "lambda_arn" {
  description = "ARN of the print notification Lambda."
  value       = aws_lambda_function.print.arn
}

output "queue_arn" {
  description = "ARN of the SQS queue feeding the Lambda."
  value       = module.plumbing.queue_arn
}

output "queue_url" {
  description = "URL of the SQS queue feeding the Lambda."
  value       = module.plumbing.queue_url
}

output "subscription_arn" {
  description = "ARN of the SNS subscription to the queue."
  value       = module.plumbing.subscription_arn
}
