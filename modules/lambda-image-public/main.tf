locals {
  tags                = merge({ managed_by = "lambdacron" }, var.tags)
  build_context_paths = var.build_context_paths == null ? [var.build_context] : var.build_context_paths
  build_context_hash = sha1(join("", [
    for file_path in flatten([
      for base_path in local.build_context_paths :
      flatten([
        for pattern in var.build_context_patterns :
        [for relative_path in fileset(base_path, pattern) : "${base_path}/${relative_path}"]
      ])
    ]) :
    filesha256(file_path)
  ]))
}

data "aws_region" "current" {}

resource "aws_ecrpublic_repository" "image" {
  repository_name = var.repository_name

  catalog_data {
    description       = var.short_description
    about_text        = var.about_text
    usage_text        = var.usage_text
    architectures     = var.architectures
    operating_systems = var.operating_systems
  }

  lifecycle {
    precondition {
      condition     = data.aws_region.current.name == "us-east-1"
      error_message = "Public ECR repositories must be created in us-east-1. Pass an aws provider configured for us-east-1."
    }
  }

  tags = local.tags
}

resource "null_resource" "build_and_push" {
  triggers = {
    image_tag          = var.image_tag
    repository_uri     = aws_ecrpublic_repository.image.repository_uri
    platform           = var.platform
    build_context_hash = local.build_context_hash
    dockerfile_path    = var.dockerfile_path
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOC
      set -euo pipefail
      # Isolate registry credentials from the host keychain in a temporary Docker config.
      # Preserve the selected daemon endpoint before hiding contexts, and seed auths
      # to prevent Docker from auto-detecting a host credential helper.
      if [[ -n "$${DOCKER_CONTEXT:-}" ]]; then
        DOCKER_HOST="$(docker context inspect "$DOCKER_CONTEXT" --format '{{.Endpoints.docker.Host}}')"
      elif [[ -z "$${DOCKER_HOST:-}" ]]; then
        DOCKER_HOST="$(docker context inspect --format '{{.Endpoints.docker.Host}}')"
      fi
      export DOCKER_HOST
      unset DOCKER_CONTEXT
      DOCKER_CONFIG="$(mktemp -d)"
      export DOCKER_CONFIG
      trap 'rm -rf "$DOCKER_CONFIG"' EXIT
      printf '%s\n' '{"auths":{"public.ecr.aws":{}}}' > "$DOCKER_CONFIG/config.json"
      aws ecr-public get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin public.ecr.aws
      docker buildx build --platform ${var.platform} -f ${var.dockerfile_path} -t ${aws_ecrpublic_repository.image.repository_uri}:${var.image_tag} ${var.build_context}
      docker push ${aws_ecrpublic_repository.image.repository_uri}:${var.image_tag}
    EOC
  }
}
