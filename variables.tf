variable "lambda_image_uri" {
  description = "URI of the Lambda container image."
  type        = string
}

variable "schedule_expression" {
  description = "EventBridge schedule expression (e.g., rate(5 minutes) or cron(0 12 * * ? *))."
  type        = string
}

variable "topic_name" {
  description = "Name of the shared SNS topic for scheduled results."
  type        = string
  default     = "cloud-cron-results.fifo"

  validation {
    condition     = !var.fifo_topic || can(regex("\\.fifo$", var.topic_name))
    error_message = "When fifo_topic is true, topic_name must end with .fifo."
  }
}

variable "fifo_topic" {
  description = "Whether to create the SNS topic as FIFO."
  type        = bool
  default     = true
}

variable "content_based_deduplication" {
  description = "Whether FIFO SNS content-based deduplication is enabled."
  type        = bool
  default     = true
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
