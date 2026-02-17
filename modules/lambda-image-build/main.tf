locals {
  repository_name = coalesce(
    var.repository_name,
    "${basename(abspath(var.source_dir))}-source",
  )
  tags                = merge({ managed_by = "lambdacron" }, var.tags)
  dockerfile_arg      = var.dockerfile_path == null ? "" : "-f ${var.dockerfile_path} "
  build_context_paths = var.build_context_paths == null ? [var.source_dir] : var.build_context_paths
  build_context_hash = sha1(join("", [
    for file_path in flatten([
      for base_path in local.build_context_paths :
      [for file_path in fileset(base_path, "**") : "${base_path}/${file_path}"]
    ]) :
    filesha256(file_path)
  ]))
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_ecr_repository" "lambda_image" {
  name                 = local.repository_name
  force_delete         = true
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

resource "aws_ecr_lifecycle_policy" "cleanup" {
  repository = aws_ecr_repository.lambda_image.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "null_resource" "build_and_push" {
  triggers = {
    image_tag       = var.image_tag
    repository_url  = aws_ecr_repository.lambda_image.repository_url
    platform        = var.platform
    build_context   = local.build_context_hash
    repository_name = aws_ecr_repository.lambda_image.name
    dockerfile_path = var.dockerfile_path
  }

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command     = <<-EOC
      set -euo pipefail
      aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com
      docker buildx build --platform ${var.platform} ${local.dockerfile_arg}-t ${aws_ecr_repository.lambda_image.repository_url}:${var.image_tag} ${var.source_dir}
      docker push ${aws_ecr_repository.lambda_image.repository_url}:${var.image_tag}
    EOC
  }

  depends_on = [
    aws_ecr_lifecycle_policy.cleanup,
  ]
}

data "aws_ecr_image" "built" {
  repository_name = aws_ecr_repository.lambda_image.name
  image_tag       = var.image_tag

  depends_on = [
    null_resource.build_and_push,
  ]
}
