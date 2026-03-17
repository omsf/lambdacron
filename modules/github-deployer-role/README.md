# GitHub Deployer Role Module

Creates an IAM role that GitHub Actions can assume through OIDC and attaches selected LambdaCron permission sets.

## Usage

```hcl
module "github_deployer_role" {
  source = "./modules/github-deployer-role"

  role_name                = "lambdacron-deployer"
  github_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"

  github_subjects = [
    "repo:my-org/cloud-cron-consumer:ref:refs/heads/main",
    "repo:my-org/cloud-cron-consumer:environment:prod",
  ]

  github_job_workflow_refs = [
    "my-org/cloud-cron-consumer/.github/workflows/deploy.yml@refs/heads/main",
  ]

  permission_sets = [
    "root",
    "print-notification",
    "email-notification",
    "lambda-image-build",
  ]

  allowed_resource_name_prefixes = [
    "lambdacron",
  ]

  tags = {
    environment = "prod"
  }
}
```

## Permission Sets

- `scheduled-lambda`: Lambda + IAM execution-role/policy wiring + EventBridge schedule management + ECR image lookup/repository policy permissions required for image-based function create/update.
- `notification-plumbing`: SNS subscription + SQS queue + Lambda event source mapping.
- `print-notification`: Reuses `notification-plumbing` and adds notification Lambda/IAM deployment permissions.
- `email-notification`: Reuses `notification-plumbing` and adds notification Lambda/IAM deployment permissions.
- `sms-notification`: Reuses `notification-plumbing` and adds notification Lambda/IAM deployment permissions.
- `lambda-image-build`: Private ECR repository management, private repository policy management, and image push permissions.
- `lambda-image-republish`: Reuses `lambda-image-build` and adds public ECR auth + read permissions.
- `lambda-image-public`: Public ECR repository management + image push permissions.
- `root`: Reuses `scheduled-lambda` and adds shared SNS topic management.

## Inputs

- `role_name` (string): IAM role name.
- `role_description` (string): IAM role description.
- `max_session_duration` (number): Max assume-role session duration (seconds).
- `github_oidc_provider_arn` (string): GitHub OIDC provider ARN.
- `github_audience` (string): OIDC token audience, default `sts.amazonaws.com`.
- `github_subjects` (list(string)): Allowed OIDC subject patterns.
- `github_job_workflow_refs` (list(string)): Optional allowed OIDC `job_workflow_ref` patterns for workflow-level restriction.
- `permission_sets` (set(string)): Permission sets to attach.
- `additional_policy_arns` (list(string)): Extra managed policies to attach.
- `allowed_resource_name_prefixes` (set(string)): Allowed name prefixes for deployer-managed resources; defaults to `["lambdacron"]`.
- `tags` (map(string)): Resource tags.

## Scoping Behavior

- Permission-set policies are scoped to the current AWS account and to resources whose names start with values in `allowed_resource_name_prefixes`.
- `iam:PassRole` is restricted to scoped IAM role ARNs and requires `iam:PassedToService = lambda.amazonaws.com`.
- A small set of actions remains wildcard-scoped where AWS APIs do not support resource-level scoping (for example some create/authentication APIs such as `sns:CreateTopic`, `sqs:CreateQueue`, `ecr:GetAuthorizationToken`, and event source mapping APIs).

## Outputs

- `role_arn`: IAM role ARN.
- `role_name`: IAM role name.
- `permission_set_policy_arns`: Map of selected permission-set names to created policy ARNs.
- `selected_permission_sets`: Sorted selected permission-set names.
- `available_permission_sets`: Map of all available permission-set names and descriptions.
- `assume_role_policy_json`: Rendered trust policy JSON.
