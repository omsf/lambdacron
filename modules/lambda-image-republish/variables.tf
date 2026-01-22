variable "source_lambda_repo" {
  description = "Name of the source ECR repository that already contains the Lambda image."
  type        = string
}

variable "source_lambda_tag" {
  description = "Image tag to republish from the source repository."
  type        = string
}

variable "source_registry_id" {
  description = "Optional registry ID for the source repository. Defaults to the current account."
  type        = string
  default     = null
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
