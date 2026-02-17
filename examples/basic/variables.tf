variable "aws_region" {
  description = "AWS region for the example deployment."
  type        = string
  default     = "us-east-1"
}

variable "repository_name" {
  description = "Optional repository name for the source-built Lambda image. Defaults to <basename>-source."
  type        = string
  default     = null
}

variable "image_tag" {
  description = "Tag to use for the locally built image."
  type        = string
  default     = "demo"
}

variable "platform" {
  description = "Target platform for the container build."
  type        = string
  default     = "linux/amd64"
}

variable "notification_image_repository_url" {
  description = "Repository URL hosting the notification-container image to republish."
  type        = string
  default     = "public.ecr.aws/i9p4w7k9/lambdacron-notifications"
}

variable "notification_image_tag" {
  description = "Tag for the notification-container image to republish."
  type        = string
  default     = "latest"
}

variable "enable_republish" {
  description = "Set to true to republish from an existing ECR repository instead of building locally."
  type        = bool
  default     = false
}

variable "source_lambda_repo" {
  description = "Source ECR repository to republish from when enable_republish is true."
  type        = string
  default     = null
}

variable "source_lambda_tag" {
  description = "Tag in the source repository to republish."
  type        = string
  default     = "latest"
}

variable "destination_repository_name" {
  description = "Optional destination repository name when republishing. Defaults to <source>-local."
  type        = string
  default     = null
}

variable "enable_kms_encryption" {
  description = "Set to true to use KMS encryption for the local repository."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN for republishing when enable_kms_encryption is true."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to created resources."
  type        = map(string)
  default     = {}
}

variable "schedule_expression" {
  description = "EventBridge schedule expression for the example Lambda."
  type        = string
  default     = "rate(1 hour)"
}

variable "lambda_name" {
  description = "Name for the scheduled Lambda function."
  type        = string
  default     = "lambdacron-basic"
}

variable "create_test_url" {
  description = "Whether to create a Lambda Function URL for on-demand test invokes."
  type        = bool
  default     = false
}

variable "email_sender" {
  description = "Sender email address for the SES notifier."
  type        = string
}

variable "email_recipients" {
  description = "Recipient email addresses for the SES notifier."
  type        = list(string)
}

variable "email_reply_to" {
  description = "Reply-to email addresses for the SES notifier."
  type        = list(string)
  default     = []
}
