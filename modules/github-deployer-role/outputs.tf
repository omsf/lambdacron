output "role_arn" {
  description = "ARN of the GitHub deployer role."
  value       = aws_iam_role.deployer.arn
}

output "role_name" {
  description = "Name of the GitHub deployer role."
  value       = aws_iam_role.deployer.name
}

output "permission_set_policy_arns" {
  description = "Managed policy ARNs created for each selected permission set."
  value = {
    for name, policy in aws_iam_policy.permission_set : name => policy.arn
  }
}

output "selected_permission_sets" {
  description = "Permission set names attached to this role."
  value       = sort(keys(aws_iam_policy.permission_set))
}

output "available_permission_sets" {
  description = "Catalog of all available permission set names and descriptions."
  value = {
    for name, set_definition in local.permission_set_catalog : name => set_definition.description
  }
}

output "assume_role_policy_json" {
  description = "Rendered trust policy JSON for the role."
  value       = data.aws_iam_policy_document.assume_role.json
}
