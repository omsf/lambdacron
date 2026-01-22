output "lambda_image_uri" {
  description = "URI of the local Lambda container image."
  value       = local.destination_image_uri
}

output "lambda_image_uri_with_digest" {
  description = "Digest-pinned URI of the local Lambda container image."
  value       = "${aws_ecr_repository.destination.repository_url}@${data.aws_ecr_image.destination.image_digest}"
}

output "destination_repository_url" {
  description = "URL of the destination ECR repository."
  value       = aws_ecr_repository.destination.repository_url
}

output "destination_repository_arn" {
  description = "ARN of the destination ECR repository."
  value       = aws_ecr_repository.destination.arn
}

output "destination_repository_name" {
  description = "Name of the destination ECR repository."
  value       = aws_ecr_repository.destination.name
}
