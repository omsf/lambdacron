# Email Notification Module

Notification Lambda that renders subject/text/html templates and sends via SES.

## Usage

```hcl
module "email_notification" {
  source = "./modules/email-notification"

  sns_topic_arn   = aws_sns_topic.example.arn
  result_types    = ["example"]
  fifo_queue_name = "example-email.fifo"
  lambda_image_uri = module.email_image.image_uri_with_digest

  sender     = "noreply@example.com"
  recipients = ["alice@example.com", "bob@example.com"]

  subject_template_file = "${path.module}/templates/subject.txt"
  text_template_file    = "${path.module}/templates/body.txt"
  html_template_file    = "${path.module}/templates/body.html"
}
```

## Inputs

- `sns_topic_arn` (string): SNS topic ARN that feeds the notification queue.
- `result_types` (list(string)): Result types to subscribe to. Empty means all.
- `fifo_queue_name` (string): Name of the FIFO SQS queue (must end with `.fifo`).
- `lambda_image_uri` (string): URI of the Lambda container image.
- `lambda_name` (string): Optional name for the Lambda function.
- `subject_template_env_var` (string): Environment variable for the subject template. Default `EMAIL_SUBJECT_TEMPLATE`.
- `text_template_env_var` (string): Environment variable for the plaintext template. Default `EMAIL_TEXT_TEMPLATE`.
- `html_template_env_var` (string): Environment variable for the HTML template. Default `EMAIL_HTML_TEMPLATE`.
- `subject_template_file` (string): Path to the subject template file.
- `text_template_file` (string): Path to the plaintext template file.
- `html_template_file` (string): Path to the HTML template file.
- `sender` (string): Sender email address for SES.
- `recipients` (list(string)): Recipient email addresses for SES.
- `reply_to` (list(string)): Reply-to email addresses. Default `[]`.
- `timeout` (number): Lambda timeout in seconds. Default `30`.
- `memory_size` (number): Lambda memory size in MB. Default `256`.
- `batch_size` (number): Max records per Lambda invocation. Default `10`.
- `enabled` (bool): Enable the event source mapping. Default `true`.
- `tags` (map(string)): Tags applied to resources.

## Outputs

- `lambda_arn`: ARN of the email notification Lambda.
- `queue_arn`: ARN of the notification SQS queue.
- `queue_url`: URL of the notification SQS queue.
- `subscription_arn`: ARN of the SNS subscription.
