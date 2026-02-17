# Lambda Image Public (ECR Public)

This module creates a public ECR repository and builds/pushes a container image into it using `docker buildx`.

## Usage

```hcl
module "notification_image" {
  source = "../modules/lambda-image-public"

  repository_name = "lambdacron-notifications"
  image_tag       = "latest"

  short_description = "LambdaCron notification handlers (email + print)"
  about_text        = "Shared Lambda container image with built-in email and print notification handlers."
  usage_text        = "Use handler entrypoints lambda.email_handler or lambda.print_handler with the LambdaCron notification modules."

  build_context   = abspath("${path.module}/..")
  dockerfile_path = "${path.module}/Dockerfile"

  build_context_paths = [
    abspath(path.module),
    abspath("${path.module}/../src/lambdacron"),
  ]

  providers = {
    aws = aws.us_east_1
  }
}
```

## Inputs

- `repository_name` (string): Public ECR repository name.
- `image_tag` (string): Tag to apply to the image. Default `latest`.
- `platform` (string): Target platform for the container build. Default `linux/amd64`.
- `short_description` (string): Short description for the public ECR catalog. Default empty.
- `about_text` (string): Long-form about text for the public ECR catalog. Default empty.
- `usage_text` (string): Usage text for the public ECR catalog. Default empty.
- `architectures` (list(string)): Supported CPU architectures for the catalog listing. Default `["x86-64"]`.
- `operating_systems` (list(string)): Supported operating systems for the catalog listing. Default `["Linux"]`.
- `build_context` (string): Docker build context path.
- `dockerfile_path` (string): Path to the Dockerfile.
- `build_context_paths` (list(string)): Paths to include when hashing build context for rebuilds. Default `null` (uses `build_context`).
- `build_context_patterns` (list(string)): Glob patterns to include when hashing build context for rebuilds. Default `["**"]`.
- `tags` (map(string)): Tags to apply to created resources. Default `{}`.

## Outputs

- `repository_arn`: ARN of the public ECR repository.
- `repository_uri`: URI of the public ECR repository.
- `image_uri`: Full image URI including the tag.

## Notes

- Requires Docker with `buildx` and `aws` CLI credentials capable of creating public ECR repositories.
- Public ECR repositories can only be created in `us-east-1`; pass a provider configured for `us-east-1` via `providers`.
