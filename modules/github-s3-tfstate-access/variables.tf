variable "role_name" {
  description = "IAM role name to attach the backend access policy to."
  type        = string

  validation {
    condition     = length(trimspace(var.role_name)) > 0
    error_message = "role_name must be a non-empty IAM role name."
  }
}

variable "state_bucket" {
  description = "S3 bucket name that stores Terraform/OpenTofu state."
  type        = string

  validation {
    condition     = length(trimspace(var.state_bucket)) > 0
    error_message = "state_bucket must be a non-empty S3 bucket name."
  }
}

variable "locks_table" {
  description = "Optional DynamoDB table name used for Terraform/OpenTofu state locking."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.locks_table == null || length(trimspace(var.locks_table)) > 0
    error_message = "locks_table must be null or a non-empty DynamoDB table name."
  }
}

variable "aws_region" {
  description = "Optional AWS region override for the DynamoDB lock table; defaults to the configured AWS provider region."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.aws_region == null || length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must be null or a non-empty AWS region name."
  }
}

variable "tags" {
  description = "Tags to apply to created IAM policy resources."
  type        = map(string)
  default     = {}
}

variable "github_repository" {
  description = "GitHub repository in owner/repo format. This module always manages TF_STATE_BUCKET and, when locks_table is set, TF_STATE_TABLE GitHub Actions secrets for that repository."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "github_repository must be in owner/repo format."
  }
}
