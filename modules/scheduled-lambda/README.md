# Scheduled Lambda Module

Provision a container-based Lambda function that runs on an EventBridge schedule and publishes to a shared SNS topic.

## Usage

```hcl
resource "aws_sns_topic" "results" {
  name = "cloud-cron-results"
}

resource "aws_iam_policy" "terminate_instance" {
  name = "allow-terminate-instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:TerminateInstances"]
        Resource = ["arn:aws:ec2:us-west-2:123456789012:instance/i-0123456789abcdef0"]
      }
    ]
  })
}

module "scheduled_lambda" {
  source = "./modules/scheduled-lambda"

  lambda_image_uri    = "123456789012.dkr.ecr.us-west-2.amazonaws.com/my-lambda:latest"
  schedule_expression = "rate(5 minutes)"
  sns_topic_arn       = aws_sns_topic.results.arn

  lambda_env = {
    LOG_LEVEL = "info"
  }

  additional_policy_arns = [
    aws_iam_policy.terminate_instance.arn,
  ]
}
```

## Inputs

- `lambda_image_uri` (string): URI of the Lambda container image.
- `schedule_expression` (string): EventBridge schedule expression.
- `sns_topic_arn` (string): SNS topic ARN for publishing results.
- `lambda_env` (map(string)): Additional environment variables for the Lambda.
- `timeout` (number): Lambda timeout in seconds.
- `memory_size` (number): Lambda memory size in MB.
- `lambda_name` (string): Optional name override for the Lambda.
- `image_command` (list(string)): Optional override for the container CMD/handler.
- `tags` (map(string)): Tags to apply to created resources.
- `create_test_url` (bool): Create a public Lambda Function URL for temporary testing only (not for production). This URL has no auth and is publicly accessible, so it can be abused.
- `additional_policy_arns` (list(string)): Additional IAM managed policy ARNs to attach to the Lambda execution role.

## Outputs

- `lambda_arn`: ARN of the scheduled Lambda function.
- `execution_role_arn`: ARN of the Lambda execution role.
- `execution_role_name`: Name of the Lambda execution role.
- `log_group_name`: CloudWatch log group name for the Lambda.
- `schedule_rule_name`: Name of the EventBridge schedule rule.
- `test_function_url`: Function URL for temporary testing (null if disabled).
