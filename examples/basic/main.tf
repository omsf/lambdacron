provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = merge(
    { managed_by = "cloudcron" },
    var.tags,
    { project = "cloud-cron-example-basic" },
  )
}

module "lambda_image_build" {
  source = "../../modules/lambda-image-build"

  source_dir      = "${path.module}/../.."
  dockerfile_path = "${path.module}/lambda/Dockerfile"
  build_context_paths = [
    "${path.module}/lambda",
    "${path.module}/../../src/cloud_cron",
  ]
  repository_name = var.repository_name
  image_tag       = var.image_tag
  platform        = var.platform
  tags            = local.common_tags
}

module "print_lambda_image_build" {
  source = "../../modules/lambda-image-build"

  source_dir      = "${path.module}/../.."
  dockerfile_path = "${path.module}/print-notifier/Dockerfile"
  build_context_paths = [
    "${path.module}/print-notifier",
    "${path.module}/../../src/cloud_cron",
  ]
  repository_name = var.print_repository_name
  image_tag       = var.image_tag
  platform        = var.platform
  tags            = local.common_tags
}

module "email_lambda_image_build" {
  source = "../../modules/lambda-image-build"

  source_dir      = "${path.module}/../.."
  dockerfile_path = "${path.module}/email-notifier/Dockerfile"
  build_context_paths = [
    "${path.module}/email-notifier",
    "${path.module}/../../src/cloud_cron",
  ]
  repository_name = var.email_repository_name
  image_tag       = var.image_tag
  platform        = var.platform
  tags            = local.common_tags
}

module "lambda_container_republish" {
  count  = var.enable_republish ? 1 : 0
  source = "../../modules/lambda-image-republish"

  source_lambda_repo          = var.source_lambda_repo
  source_lambda_tag           = var.source_lambda_tag
  source_registry_id          = var.source_registry_id
  destination_repository_name = var.destination_repository_name
  enable_kms_encryption       = var.enable_kms_encryption
  kms_key_arn                 = var.kms_key_arn
  tags                        = local.common_tags
}

locals {
  active_lambda_image_uri = var.enable_republish ? module.lambda_container_republish[0].lambda_image_uri_with_digest : module.lambda_image_build.image_uri_with_digest
  active_print_image_uri  = module.print_lambda_image_build.image_uri_with_digest
  active_email_image_uri  = module.email_lambda_image_build.image_uri_with_digest
}

module "cloud_cron" {
  source = "../.."

  aws_region          = var.aws_region
  lambda_image_uri    = local.active_lambda_image_uri
  schedule_expression = var.schedule_expression
  lambda_name         = var.lambda_name

  tags = local.common_tags
}

module "print_notification" {
  source = "../../modules/print-notification"

  sns_topic_arn    = module.cloud_cron.sns_topic_arn
  fifo_queue_name  = "example-print.fifo"
  lambda_image_uri = local.active_print_image_uri
  template_file    = "${path.module}/templates/print.txt"

  tags = local.common_tags
}

module "email_notification" {
  source = "../../modules/email-notification"

  sns_topic_arn    = module.cloud_cron.sns_topic_arn
  fifo_queue_name  = "example-email.fifo"
  lambda_image_uri = local.active_email_image_uri

  sender     = var.email_sender
  recipients = var.email_recipients
  reply_to   = var.email_reply_to

  subject_template_file = "${path.module}/templates/email-subject.txt"
  text_template_file    = "${path.module}/templates/email-body.txt"
  html_template_file    = "${path.module}/templates/email-body.html"

  tags = local.common_tags
}

output "built_image_uri" {
  description = "Image URI built from examples/basic/lambda."
  value       = module.lambda_image_build.image_uri
}

output "local_image_uri" {
  description = "Image URI from the local republish module when enabled."
  value       = length(module.lambda_container_republish) > 0 ? module.lambda_container_republish[0].lambda_image_uri : null
}

output "active_lambda_image_uri" {
  description = "Image URI to feed into downstream scheduled Lambda modules."
  value       = local.active_lambda_image_uri
}

output "scheduled_lambda_arn" {
  description = "ARN of the scheduled Lambda."
  value       = module.cloud_cron.scheduled_lambda_arn
}
