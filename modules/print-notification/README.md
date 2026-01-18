# Print Notification Module

Notification Lambda that renders a template and prints it. Intended for testing.

## Usage

```hcl
module "print_notification" {
  source = "./modules/print-notification"

  sns_topic_arn   = aws_sns_topic.example.arn
  fifo_queue_name = "example-print.fifo"
  lambda_image_uri = module.print_image.image_uri_with_digest

  template_file = "${path.module}/templates/print.txt"
}
```

## Inputs

- `sns_topic_arn` (string): SNS topic ARN that feeds the notification queue.
- `fifo_queue_name` (string): Name of the FIFO SQS queue (must end with `.fifo`).
- `lambda_image_uri` (string): URI of the Lambda container image.
- `lambda_name` (string): Optional name for the Lambda function.
- `template_env_var` (string): Environment variable for the template. Default `TEMPLATE`.
- `template_file` (string): Path to the template file stored in the template env var.
- `timeout` (number): Lambda timeout in seconds. Default `30`.
- `memory_size` (number): Lambda memory size in MB. Default `256`.
- `batch_size` (number): Max records per Lambda invocation. Default `10`.
- `enabled` (bool): Enable the event source mapping. Default `true`.
- `tags` (map(string)): Tags applied to resources.

## Outputs

- `lambda_arn`: ARN of the print notification Lambda.
- `queue_arn`: ARN of the notification SQS queue.
- `queue_url`: URL of the notification SQS queue.
- `subscription_arn`: ARN of the SNS subscription.
