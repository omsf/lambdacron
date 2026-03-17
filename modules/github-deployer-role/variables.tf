variable "role_name" {
  description = "Name for the GitHub deployer IAM role."
  type        = string
}

variable "role_description" {
  description = "Description for the GitHub deployer IAM role."
  type        = string
  default     = "Role assumed by GitHub Actions to deploy LambdaCron Terraform modules."
}

variable "max_session_duration" {
  description = "Maximum CLI/API session duration in seconds for the assumed role."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "github_oidc_provider_arn" {
  description = "ARN for the IAM OIDC provider for GitHub Actions (token.actions.githubusercontent.com)."
  type        = string
}

variable "github_audience" {
  description = "OIDC audience that GitHub includes in the token."
  type        = string
  default     = "sts.amazonaws.com"
}

variable "github_subjects" {
  description = "Allowed GitHub OIDC subject patterns (for example repo:my-org/my-repo:ref:refs/heads/main)."
  type        = list(string)

  validation {
    condition     = length(var.github_subjects) > 0
    error_message = "github_subjects must include at least one allowed subject pattern."
  }
}

variable "github_job_workflow_refs" {
  description = "Optional allowed GitHub OIDC job_workflow_ref patterns (for example my-org/my-repo/.github/workflows/deploy.yml@refs/heads/main)."
  type        = list(string)
  default     = []
}

variable "permission_sets" {
  description = "Permission set names to attach to the deployer role. Use output.available_permission_sets to discover valid names."
  type        = set(string)

  validation {
    condition     = length(var.permission_sets) > 0
    error_message = "permission_sets must contain at least one module permission set."
  }
}

variable "additional_policy_arns" {
  description = "Additional pre-existing IAM managed policy ARNs to attach to the role."
  type        = list(string)
  default     = []
}

variable "allowed_resource_name_prefixes" {
  description = "Allowed resource name prefixes for deployer-managed IAM roles/policies, Lambda functions, EventBridge rules, SNS topics, SQS queues, and ECR repositories."
  type        = set(string)
  default     = ["lambdacron"]

  validation {
    condition     = length(var.allowed_resource_name_prefixes) > 0 && alltrue([for prefix in var.allowed_resource_name_prefixes : length(trimspace(prefix)) > 0])
    error_message = "allowed_resource_name_prefixes must contain at least one non-empty prefix."
  }
}

variable "tags" {
  description = "Tags to apply to all created resources."
  type        = map(string)
  default     = {}
}
