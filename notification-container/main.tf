provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

locals {
  tags = merge({ managed_by = "lambdacron" }, var.tags)

  build_context   = abspath("${path.module}/..")
  dockerfile_path = "${path.module}/Dockerfile"
  build_context_paths = [
    abspath(path.module),
    abspath("${path.module}/../src/lambdacron"),
  ]
}

module "notification_image" {
  source = "../modules/lambda-image-public"

  repository_name   = var.repository_name
  image_tag         = var.image_tag
  platform          = var.platform
  short_description = var.short_description
  about_text        = var.about_text
  usage_text        = var.usage_text
  architectures     = var.architectures
  operating_systems = var.operating_systems

  build_context       = local.build_context
  dockerfile_path     = local.dockerfile_path
  build_context_paths = local.build_context_paths
  build_context_patterns = [
    "notification-container/Dockerfile",
    "notification-container/lambda.py",
    "notification-container/requirements.txt",
    "src/lambdacron/**/*.py",
  ]

  tags = local.tags

  providers = {
    aws = aws.us_east_1
  }
}
