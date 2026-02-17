locals {
  source_repo_parts = split("/", var.source_lambda_repo)
  source_namespace  = local.source_repo_parts[1]
  source_repo_name  = local.source_repo_parts[2]
  source_repo       = "${local.source_namespace}/${local.source_repo_name}"
  repository_name   = coalesce(var.destination_repository_name, "${local.source_repo_name}-local")
  tags              = merge({ managed_by = "lambdacron" }, var.tags)
  source_image_uri = format(
    "public.ecr.aws/%s:%s",
    local.source_repo,
    var.source_lambda_tag,
  )
  destination_image_uri = format(
    "%s:%s",
    aws_ecr_repository.destination.repository_url,
    var.source_lambda_tag,
  )
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_ecr_repository" "destination" {
  name                 = local.repository_name
  force_delete         = true
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = var.enable_kms_encryption ? "KMS" : "AES256"
    kms_key         = var.enable_kms_encryption ? var.kms_key_arn : null
  }

  tags = local.tags
}

resource "aws_ecr_repository_policy" "self_access" {
  repository = aws_ecr_repository.destination.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountPushPull"
        Effect = "Allow"
        Action = ["ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:BatchCheckLayerAvailability", "ecr:PutImage", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload"]
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })
}

resource "null_resource" "republish_image" {
  triggers = {
    source_repository           = local.source_repo
    source_tag                  = var.source_lambda_tag
    destination_repository      = aws_ecr_repository.destination.repository_url
    destination_image_tag       = var.source_lambda_tag
    enable_kms_encryption       = tostring(var.enable_kms_encryption)
    destination_repository_name = aws_ecr_repository.destination.name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command     = <<-EOC
      set -euo pipefail
      aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
      aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com
      docker pull ${local.source_image_uri}
      docker tag ${local.source_image_uri} ${local.destination_image_uri}
      docker push ${local.destination_image_uri}
    EOC
  }

  depends_on = [
    aws_ecr_repository_policy.self_access,
  ]
}

data "aws_ecr_image" "destination" {
  repository_name = aws_ecr_repository.destination.name
  image_tag       = var.source_lambda_tag

  depends_on = [
    null_resource.republish_image,
  ]
}
