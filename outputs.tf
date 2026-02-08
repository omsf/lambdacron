output "sns_topic_arn" {
  description = "ARN of the shared SNS topic."
  value       = aws_sns_topic.results.arn
}

output "sns_topic_name" {
  description = "Name of the shared SNS topic."
  value       = aws_sns_topic.results.name
}

output "scheduled_lambda_arn" {
  description = "ARN of the scheduled Lambda."
  value       = module.scheduled_lambda.lambda_arn
}

output "scheduled_lambda_role_arn" {
  description = "ARN of the scheduled Lambda execution role."
  value       = module.scheduled_lambda.execution_role_arn
}

output "scheduled_lambda_log_group" {
  description = "CloudWatch log group name for the scheduled Lambda."
  value       = module.scheduled_lambda.log_group_name
}

output "schedule_rule_name" {
  description = "EventBridge schedule rule name."
  value       = module.scheduled_lambda.schedule_rule_name
}

output "scheduled_lambda_test_url" {
  description = "Lambda Function URL for on-demand test invokes (null if disabled)."
  value       = module.scheduled_lambda.test_function_url
}
