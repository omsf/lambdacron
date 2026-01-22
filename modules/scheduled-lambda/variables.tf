variable "lambda_image_uri" {
  description = "URI of the Lambda container image."
  type        = string
}

variable "schedule_expression" {
  description = "EventBridge schedule expression (e.g., rate(5 minutes) or cron(0 12 * * ? *))."
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN to publish scheduled results."
  type        = string
}

variable "lambda_env" {
  description = "Additional environment variables to pass to the Lambda function."
  type        = map(string)
  default     = {}
}

variable "timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda memory size in MB."
  type        = number
  default     = 256
}

variable "lambda_name" {
  description = "Optional name for the Lambda function."
  type        = string
  default     = null
}

variable "image_command" {
  description = "Optional override for the container CMD/handler."
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}
