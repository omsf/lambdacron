variable "sns_topic_arn" {
  description = "SNS topic ARN that feeds the notification queue."
  type        = string
}

variable "result_types" {
  description = "Result types to subscribe to; empty means all."
  type        = list(string)
  default     = []
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

variable "subject_template_env_var" {
  description = "Environment variable that stores the subject template."
  type        = string
  default     = "EMAIL_SUBJECT_TEMPLATE"
}

variable "text_template_env_var" {
  description = "Environment variable that stores the plaintext template."
  type        = string
  default     = "EMAIL_TEXT_TEMPLATE"
}

variable "html_template_env_var" {
  description = "Environment variable that stores the HTML template."
  type        = string
  default     = "EMAIL_HTML_TEMPLATE"
}

variable "subject_template_file" {
  description = "Path to the subject template file."
  type        = string
}

variable "text_template_file" {
  description = "Path to the plaintext template file."
  type        = string
}

variable "html_template_file" {
  description = "Path to the HTML template file."
  type        = string
}

variable "sender" {
  description = "Sender email address for SES."
  type        = string
}

variable "recipients" {
  description = "Recipient email addresses for SES."
  type        = list(string)
}

variable "reply_to" {
  description = "Optional reply-to email addresses."
  type        = list(string)
  default     = []
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
