variable "repository_name" {
  description = "Public ECR repository name."
  type        = string
}

variable "image_tag" {
  description = "Tag to apply to the image."
  type        = string
  default     = "latest"
}

variable "platform" {
  description = "Target platform for the container build."
  type        = string
  default     = "linux/amd64"
}

variable "short_description" {
  description = "Short description for the public ECR catalog."
  type        = string
  default     = ""
}

variable "about_text" {
  description = "Long-form about text for the public ECR catalog."
  type        = string
  default     = ""
}

variable "usage_text" {
  description = "Usage text for the public ECR catalog."
  type        = string
  default     = ""
}

variable "architectures" {
  description = "Supported CPU architectures for the catalog listing."
  type        = list(string)
  default     = ["x86-64"]
}

variable "operating_systems" {
  description = "Supported operating systems for the catalog listing."
  type        = list(string)
  default     = ["Linux"]
}

variable "build_context" {
  description = "Docker build context path."
  type        = string
}

variable "dockerfile_path" {
  description = "Path to the Dockerfile."
  type        = string
}

variable "build_context_paths" {
  description = "Paths to include when hashing build context for rebuilds."
  type        = list(string)
  default     = null
}

variable "build_context_patterns" {
  description = "Glob patterns to include when hashing build context for rebuilds."
  type        = list(string)
  default     = ["**"]
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}
