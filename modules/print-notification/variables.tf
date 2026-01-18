variable "sns_topic_arn" {
  description = "SNS topic ARN that feeds the notification queue."
  type        = string
}

variable "fifo_queue_name" {
  description = "Name of the FIFO SQS queue (must end with .fifo)."
  type        = string
}

variable "lambda_image_uri" {
  description = "URI of the Lambda container image."
  type        = string
}

variable "lambda_name" {
  description = "Optional name for the Lambda function."
  type        = string
  default     = null
}

variable "template_env_var" {
  description = "Environment variable that stores the template."
  type        = string
  default     = "TEMPLATE"
}

variable "template_file" {
  description = "Path to the template file to store in the template environment variable."
  type        = string
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
