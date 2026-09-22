# Lambda Image Republish (Public to Private ECR)

This module creates a private ECR repository and copies a tagged image from
public ECR into it for use by Lambda in the destination AWS account and region.

## Usage

```hcl
module "lambda_image" {
  source = "github.com/omsf/lambdacron//modules/lambda-image-republish"

  source_lambda_repo          = "public.ecr.aws/example/example-lambda"
  source_lambda_tag           = "latest"
  destination_repository_name = "example-lambda-local"
}
```

## Inputs

- `source_lambda_repo` (string): Public ECR repository URL in the form
  `public.ecr.aws/<namespace>/<repository>`.
- `source_lambda_tag` (string): Source tag to copy. The destination uses the
  same tag.
- `destination_repository_name` (string): Optional private ECR repository name.
  Defaults to `<source repository>-local`.
- `enable_kms_encryption` (bool): Use KMS encryption for the destination
  repository. Default `false`.
- `kms_key_arn` (string): KMS key ARN used when KMS encryption is enabled.
  Default `null`.
- `tags` (map(string)): Tags applied to created AWS resources. Default `{}`.

## Outputs

- `lambda_image_uri`: Tagged private image URI.
- `lambda_image_uri_with_digest`: Digest-pinned private image URI.
- `destination_repository_url`: URL of the private ECR repository.
- `destination_repository_arn`: ARN of the private ECR repository.
- `destination_repository_name`: Name of the private ECR repository.

## Docker environment

- Requires Docker and AWS CLI credentials capable of pulling from public ECR,
  managing the private ECR repository, and pushing images.
- Honors an explicit `DOCKER_CONTEXT` before `DOCKER_HOST`; otherwise it
  preserves a nonempty `DOCKER_HOST` or captures the selected Docker context's
  endpoint. `DOCKER_CONTEXT` is cleared only within the provisioner after its
  endpoint is captured. The caller must start the daemon and select a valid
  context.
- Context-managed TLS certificates and settings are not copied. For remote TLS,
  supply `DOCKER_HOST`, `DOCKER_TLS_VERIFY`, and an explicit `DOCKER_CERT_PATH`
  instead.

