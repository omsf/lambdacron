variable "sns_topic_arn" {
  description = "SNS topic ARN that feeds the notification queue."
  type        = string
  validation {
    condition     = can(regex("\\.fifo$", var.sns_topic_arn))
    error_message = "sns_topic_arn must be a FIFO SNS topic ARN ending with .fifo."
  }
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function that processes SQS messages."
  type        = string
}

variable "fifo_queue_name" {
  description = "Name of the FIFO SQS queue (must end with .fifo)."
  type        = string
  validation {
    condition     = endswith(var.fifo_queue_name, ".fifo")
    error_message = "fifo_queue_name must end with .fifo."
  }
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication for the FIFO queue."
  type        = bool
  default     = true
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for the SQS queue."
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "Retention period for messages in the queue."
  type        = number
  default     = 1209600
}

variable "create_dlq" {
  description = "Whether to create a dead-letter queue."
  type        = bool
  default     = true
}

variable "max_receive_count" {
  description = "Number of receives before sending to the DLQ."
  type        = number
  default     = 5
}

variable "batch_size" {
  description = "Maximum number of records per Lambda invocation."
  type        = number
  default     = 10
}

variable "enabled" {
  description = "Enable the SQS event source mapping."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}
