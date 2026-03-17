output "policy_arn" {
  description = "ARN of the managed policy granting Terraform/OpenTofu backend access."
  value       = aws_iam_policy.terraform_backend_access.arn
}

output "policy_name" {
  description = "Name of the managed policy granting Terraform/OpenTofu backend access."
  value       = aws_iam_policy.terraform_backend_access.name
}

output "policy_json" {
  description = "Rendered IAM policy document JSON for Terraform/OpenTofu backend access."
  value       = data.aws_iam_policy_document.terraform_backend_access.json
}

output "attached_role_name" {
  description = "IAM role name that the backend access policy is attached to."
  value       = var.role_name
}

output "github_actions_secret_names" {
  description = "GitHub Actions secret names managed by this module."
  value       = sort(keys(github_actions_secret.backend))
}

output "github_actions_repository_name" {
  description = "GitHub repository name receiving managed backend secrets."
  value       = local.github_repository_name
}
