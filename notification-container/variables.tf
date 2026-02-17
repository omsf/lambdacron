variable "aws_region" {
  description = "AWS region for the public ECR repository (must be us-east-1)."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "Public ECR repositories must be created in us-east-1."
  }
}

variable "repository_name" {
  description = "Public ECR repository name."
  type        = string
  default     = "lambdacron-notifications"
}

variable "image_tag" {
  description = "Tag to apply to the notification handler image."
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
  default     = "LambdaCron notification handlers (email + print)"
}

variable "about_text" {
  description = "Long-form about text for the public ECR catalog."
  type        = string
  default     = "Shared Lambda container image with built-in email and print notification handlers."
}

variable "usage_text" {
  description = "Usage text for the public ECR catalog."
  type        = string
  default     = "Use handler entrypoints lambda.email_handler or lambda.print_handler with the LambdaCron notification modules."
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

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}
