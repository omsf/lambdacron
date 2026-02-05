output "repository_arn" {
  description = "ARN of the public ECR repository."
  value       = aws_ecrpublic_repository.image.arn
}

output "repository_uri" {
  description = "URI of the public ECR repository."
  value       = aws_ecrpublic_repository.image.repository_uri
}

output "image_uri" {
  description = "Full image URI including the tag."
  value       = "${aws_ecrpublic_repository.image.repository_uri}:${var.image_tag}"
}
