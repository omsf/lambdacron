variable "source_dir" {
  description = "Path to the directory containing the Lambda Dockerfile and source."
  type        = string
}

variable "dockerfile_path" {
  description = "Optional path to a Dockerfile to use when building the image."
  type        = string
  default     = null
}

variable "repository_name" {
  description = "Optional name for the ECR repository. Defaults to <basename>-source."
  type        = string
  default     = null
}

variable "image_tag" {
  description = "Tag to apply to the built image."
  type        = string
  default     = "latest"
}

variable "build_context_paths" {
  description = "Optional list of paths to hash for detecting build context changes."
  type        = list(string)
  default     = null
}

variable "platform" {
  description = "Target platform for the build (e.g., linux/amd64)."
  type        = string
  default     = "linux/amd64"
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}
