# Terraform Backend Access Module

Creates an IAM managed policy that grants Terraform/OpenTofu backend access to an S3 state bucket, optionally grants DynamoDB lock-table access, attaches it to a target IAM role, and manages related GitHub Actions secrets for a target repository.

## Usage

```hcl
module "terraform_backend_access" {
  source = "github.com/omsf/lambdacron//modules/github-s3-tfstate-access"

  role_name         = aws_iam_role.deployer.name
  state_bucket      = "my-tf-state"
  github_repository = "my-org/my-repo"
}
```

If you still use DynamoDB locking, set `locks_table`:

```hcl
module "terraform_backend_access" {
  source = "github.com/omsf/lambdacron//modules/github-s3-tfstate-access"

  role_name         = aws_iam_role.deployer.name
  state_bucket      = "my-tf-state"
  locks_table       = "my-tf-state-locks"
  github_repository = "my-org/my-repo"
}
```

`aws_region` is optional and only applies to DynamoDB lock-table access. If omitted, the module uses the configured AWS provider region.
The module expects GitHub provider configuration for the same repository owner as `github_repository`. It validates this and fails fast on owner mismatches.

## Inputs

- `role_name` (string): IAM role name to attach backend access policy to.
- `state_bucket` (string): S3 bucket name storing Terraform/OpenTofu state.
- `locks_table` (string, optional): DynamoDB table name storing Terraform/OpenTofu locks. Omit to use lockfile-only backends.
- `aws_region` (string, optional): Region override for the lock table. Defaults to the configured AWS provider region.
- `tags` (map(string)): Optional resource tags.
- `github_repository` (string): `owner/repo` receiving managed secrets. The module always manages `TF_STATE_BUCKET` and, if `locks_table` is provided, `TF_STATE_TABLE`.

## Outputs

- `policy_arn`: Managed policy ARN.
- `policy_name`: Managed policy name.
- `policy_json`: Rendered policy document JSON.
- `attached_role_name`: Role name the policy is attached to.
- `github_actions_secret_names`: Names of managed GitHub Actions secrets.
- `github_actions_repository_name`: Repository name receiving managed secrets.
