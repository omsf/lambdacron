output "lambda_arn" {
  description = "ARN of the scheduled Lambda function."
  value       = aws_lambda_function.scheduled.arn
}

output "execution_role_arn" {
  description = "ARN of the Lambda execution role."
  value       = aws_iam_role.lambda_role.arn
}

output "execution_role_name" {
  description = "Name of the Lambda execution role."
  value       = aws_iam_role.lambda_role.name
}

output "log_group_name" {
  description = "CloudWatch log group name for the Lambda function."
  value       = "/aws/lambda/${aws_lambda_function.scheduled.function_name}"
}

output "schedule_rule_name" {
  description = "Name of the EventBridge schedule rule."
  value       = aws_cloudwatch_event_rule.schedule.name
}

output "test_function_url" {
  description = "Function URL for on-demand test invokes (null if disabled)."
  value       = try(aws_lambda_function_url.test[0].function_url, null)
}
