variable "source_lambda_repo" {
  description = "Source public ECR repository (public.ecr.aws/<namespace>/<repo>)."
  type        = string

  validation {
    condition     = can(regex("^public\\.ecr\\.aws/[^/]+/[^/]+$", var.source_lambda_repo))
    error_message = "source_lambda_repo must be a public ECR URL like public.ecr.aws/<namespace>/<repo>."
  }
}

variable "source_lambda_tag" {
  description = "Image tag to republish from the public ECR repository."
  type        = string
}

variable "destination_repository_name" {
  description = "Optional override for the destination repository name. Defaults to <source>-local."
  type        = string
  default     = null
}

variable "enable_kms_encryption" {
  description = "Set to true to use KMS encryption for the destination ECR repository."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN to use when enable_kms_encryption is true."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}
