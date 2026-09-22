# Lambda Image Build (Private ECR)

This module creates a private ECR repository, builds a Lambda container image
from local source with Docker Buildx, and pushes the image to the repository.

## Usage

```hcl
module "lambda_image" {
  source = "github.com/omsf/lambdacron//modules/lambda-image-build"

  source_dir      = "${path.module}/lambda"
  repository_name = "my-lambda"
  image_tag       = "latest"
  platform        = "linux/amd64"
}
```

Set `dockerfile_path` when the Dockerfile is outside `source_dir` or has a
nonstandard name. Use `build_context_paths` to control which paths trigger a
rebuild; it defaults to `source_dir`.

## Inputs

- `source_dir` (string): Docker build context containing the Lambda source.
- `dockerfile_path` (string): Optional path to a Dockerfile. Default `null`.
- `repository_name` (string): Optional private ECR repository name. Defaults to
  `<source_dir basename>-source`.
- `image_tag` (string): Tag applied to the built image. Default `latest`.
- `build_context_paths` (list(string)): Optional paths hashed to detect build
  context changes. Default `null` (uses `source_dir`).
- `platform` (string): Docker build platform. Default `linux/amd64`.
- `tags` (map(string)): Tags applied to created AWS resources. Default `{}`.

## Outputs

- `image_uri`: Tagged image URI.
- `image_uri_with_digest`: Digest-pinned image URI.
- `repository_arn`: ARN of the private ECR repository.
- `repository_url`: URL of the private ECR repository.

## Docker environment

- Requires Docker with Buildx and AWS CLI credentials capable of managing the
  private ECR repository and pushing images.
- Honors an explicit `DOCKER_CONTEXT` before `DOCKER_HOST`; otherwise it
  preserves a nonempty `DOCKER_HOST` or captures the selected Docker context's
  endpoint. `DOCKER_CONTEXT` is cleared only within the provisioner after its
  endpoint is captured. The caller must start the daemon and select a valid
  context.
- Context-managed TLS certificates and settings are not copied. For remote TLS,
  supply `DOCKER_HOST`, `DOCKER_TLS_VERIFY`, and an explicit `DOCKER_CERT_PATH`
  instead.

