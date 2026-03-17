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

variable "create_test_url" {
  description = "Create a public Lambda Function URL for temporary testing only (do not use in production)."
  type        = bool
  default     = false
}

# We need the stable keys for the additional policy ARNs because with a list
# of ARNs, we either have problems with foreach on objects that are created
# in the same plan, or we have problems with count/index which makes
# resources index (order) dependent. So arbitrary stable labels are a better
# solution.
variable "additional_managed_policy_arns" {
  description = "Additional IAM managed policy ARNs to attach to the Lambda execution role, keyed by stable labels."
  type        = map(string)
  default     = {}

  validation {
    condition     = length(var.additional_managed_policy_arns) <= 10
    error_message = "additional_managed_policy_arns may contain at most 10 managed policy ARNs."
  }

  validation {
    condition = alltrue([
      for label in keys(var.additional_managed_policy_arns) :
      can(regex("^[A-Za-z0-9_-]+$", label))
    ])
    error_message = "additional_managed_policy_arns keys must match ^[A-Za-z0-9_-]+$."
  }

  validation {
    condition = alltrue([
      for policy_arn in values(var.additional_managed_policy_arns) :
      can(regex("^arn:[^:]+:iam::(aws|[0-9]{12}):policy/[A-Za-z0-9+=,.@_/-]+$", trimspace(policy_arn)))
    ])
    error_message = "additional_managed_policy_arns values must be IAM managed policy ARNs."
  }
}

variable "additional_inline_policies" {
  description = "Additional inline IAM policy JSON documents to attach to the Lambda execution role, keyed by stable labels."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for label in keys(var.additional_inline_policies) :
      can(regex("^[A-Za-z0-9_-]+$", label))
    ])
    error_message = "additional_inline_policies keys must match ^[A-Za-z0-9_-]+$."
  }

  validation {
    condition = alltrue([
      for policy_json in values(var.additional_inline_policies) :
      can(regex("\\S", policy_json)) && can(jsondecode(policy_json))
    ])
    error_message = "additional_inline_policies values must be non-empty JSON strings."
  }
}
