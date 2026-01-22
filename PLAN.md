# Cloud Cron To-Do Plan

`examples/basic` is our living testbed: we will evolve it in each phase as modules land, rather than waiting until the end.

## Phase 0: Establish repo scaffolding

- [x] Create directories: `modules/scheduled-lambda`, `modules/email-notification`, `modules/sms-notification`, `modules/lambda-container`, `examples/basic`.
- [x] Add shared Terraform version constraints/provider stubs (`versions.tf`), ignore `.terraform.lock.hcl`, and add `.gitignore`.
- [x] Wire `tofu fmt` via pre-commit hook.
- [x] Add Pixi project file with toolchain (terraform/tofu, python for lambdas)
- [x] Verify: run `terraform fmt -recursive`/`tofu fmt` and `terraform validate` at repo root; ensure pre-commit passes; ensure CI bootstrap (if added) passes locally.

## Phase 1: Lambda container image management modules

### Phase 1.1: Build Lambda container republish module (`modules/lambda-container`)
- [x] Inputs: `source_lambda_repo`, `source_lambda_tag`, optional destination repo name, KMS encryption flag.
- [x] Resources: destination ECR repo, permissions for pull/push, data source for source image digest, replication via `null_resource`/`local-exec` or pull-through cache rule.
- [x] Outputs: destination `lambda_image_uri` for scheduled module.
- [x] Verify: `terraform plan` shows repo and replication steps; document manual check (`aws ecr describe-images` for dest tag).
- [x] Example touchpoint: optionally show `examples/basic` using the local image output to feed the scheduled-lambda module (document how to toggle on/off).

### Phase 1.2: Build Lambda image-from-directory module (`modules/lambda-image-build`)
- [x] Inputs: `source_dir` (Dockerfile directory), optional `repository_name`, `image_tag` (default `latest`), `build_args`, `platform` (e.g., `linux/amd64`), tags.
- [x] Resources: ECR repository (or use provided), lifecycle policy, data sources for account/region, and `null_resource` with `local-exec` to `docker buildx build` and `docker push` the image.
- [x] Outputs: `image_uri`, repository ARN/URL.
- [x] Verify: `terraform plan` shows repo + build/push steps; document prerequisites (`docker login`/credentials).
- [x] Example touchpoint: allow `examples/basic` to build/push a simple placeholder Lambda image from a local Dockerfile as an alternative to the republish module.

## Phase 2: Build scheduled Lambda module (`modules/scheduled-lambda`)
- [x] Define inputs: `lambda_image_uri`, `schedule_expression`, `sns_topic_arns` (map topic key->ARN), optional `lambda_env`, `timeout`, `memory_size`, `tags`.
- [x] Create resources: IAM role/policy (CloudWatch Logs + `sns:Publish` to provided ARNs), Lambda from container image, EventBridge rule/target/permission.
- [x] Outputs: Lambda ARN, execution role ARN, log group name, schedule rule name.
- [x] Docs: README with usage matching IDEA example.
- [x] Example touchpoint: scaffold `examples/basic` with this module + stub SNS topic(s) and the container image outputs from Phase 1; `terraform validate/plan` should pass to prove schedule wiring.

## Phase 3: Python runtime library for custom lambdas (`src/cloud_cron/`)

Overview: turn the existing Python helpers into a reusable, testable library that makes it easy for users to author scheduled lambdas while keeping SNS wiring and logging consistent. This package will also host shared notification handler code (under `src/cloud_cron/notifications/`), while deployment/container wiring remains in Terraform modules.

Success criteria:

- A minimal, well-documented API for defining tasks and dispatching results to SNS.
- Clear guidance in `src/cloud_cron/HOWTO-custom-lambda.md` that matches the library behavior.
- Unit tests covering the core dispatch and handler flow using mocked AWS clients.

Decisions and motivations:

- Keep code in `src/cloud_cron/` to stay close to Terraform modules and examples, while enabling importable Python helpers.
- Prefer dependency injection for AWS clients to avoid real AWS calls and keep tests fast.

To-do:

- [x] Refine the base task class to be typed, injectable (boto3 session/client), and structured-logging friendly.
- [x] Add a small SNS dispatch helper that validates topic keys and emits clear errors on mismatches.
- [x] Add `src/cloud_cron/notifications/` for shared handler logic (SES/Twilio/etc.) that can be imported by notification runtimes.
- [x] Update `src/cloud_cron/HOWTO-custom-lambda.md` to show the current recommended pattern and env var expectations.
- [x] Add pytest cases with moto/mocks to cover SNS publish and mismatch errors.
- [x] Document a minimal example task module that can be used in `examples/basic` or in a client repo.

## Phase 4: Build notification modules

### Phase 4.1: Notification containers and queueing infra
- [ ] Build one container per notification channel (email, SMS, print) using shared helpers from `src/cloud_cron/notifications/`; allow build or republish via `lambda-image-build` or `lambda-container`.
- [x] Add a minimal "print" notifier handler that renders the template and logs/prints it for easy testing.
- [x] Terraform: reusable notification plumbing module (SNS FIFO topic -> SQS FIFO queue -> Lambda event source mapping) with SQS access policy output.
- [ ] Terraform: per-channel container build/publish; channel modules use the plumbing module and add channel-specific IAM and config.
- [ ] Inputs per module: `sns_topic_arn`, `fifo_queue_name`/settings, handler selector/env vars; shared tags/log retention.
- [x] Verify: `terraform validate`; example `plan`; container build succeeds locally; pytest skeleton runs.
- [x] Example touchpoint: extend `examples/basic` to include the print notifier + FIFO SNS/SQS wiring to the sample SNS topic.

### Phase 4.2: Email via SES handler (`modules/email-notification`)
- [ ] Define handler contract: expect message payload with subject/template vars; support optional config set/reply-to; log delivery status.
- [ ] Python code: SES client wrapper; load template (managed via Terraform) and render with variables; handle throttling/retries and DLQ-safe errors.
- [ ] Terraform: SES template creation; Lambda configuration/env (sender, recipients, template name, config set); permissions for SES send + logs; wire to the SES-specific container image.
- [ ] Tests: pytest with sample SNS/SQS events; stub/moto SES; validate error handling and idempotency.
- [ ] Verify: `terraform validate`; handler unit tests green; document smoke test (publish SNS message to topic -> email delivered/SES sandbox note).
- [ ] Example touchpoint: wire the email module into `examples/basic` with sample SES template/resources and document the SNS publish -> email expectation.

### Phase 4.3: SMS via Twilio handler (`modules/sms-notification`)
- [ ] Define handler contract: expect message payload with body/recipients; support per-message override of to-numbers; log Twilio SID/error.
- [ ] Python code: Twilio REST client wrapper; read SID/auth token from SSM/Secrets; handle rate limits/retries; sanitize phone numbers; DLQ-safe errors.
- [ ] Terraform: Lambda configuration/env (from-number, default recipients, secret ARNs), IAM for Secrets Manager/SSM read + logs; wire to the Twilio-specific container image.
- [ ] Tests: pytest with mocked Twilio client; cover success/failure paths and secret fetch.
- [ ] Verify: `terraform validate`; handler unit tests green; document smoke test (publish SNS message to topic -> SMS sent).
- [ ] Example touchpoint: add the SMS module to `examples/basic` (guard secrets/recipients via variables) and include a smoke path in the README.

## Phase 5: Hardening, testing, documentation, release

### Phase 5.1: Example polish and end-to-end regression (`examples/basic`)
- [ ] Consolidate prior touchpoints into a clean walkthrough (init, plan, apply, publish test message through SNS->SQS->Lambda handlers).
- [ ] Ensure defaults/variables make the example easy to run with minimal secrets, with notes for SES/Twilio sandboxing.
- [ ] Verify: `terraform fmt/validate` and `terraform plan` in example; capture expected outputs/log markers for manual SNS publish tests.

### Phase 5.2: Testing & CI
- [ ] Add `make test` to run fmt, validate, lint, and Lambda unit tests.
- [ ] Consider lightweight Terratest for scheduled-lambda wiring (guarded to skip apply by default).
- [ ] Add CI workflow (e.g., GitHub Actions) for formatting, validation, and unit tests on PRs.
- [ ] Verify: CI passes on clean tree; local `make test` passes.

### Phase 5.3: Documentation & release
- [ ] Top-level README: module overview, prerequisites (AWS creds, SES/Twilio setup), quickstart commands.
- [ ] Module READMEs: inputs/outputs tables and examples (generated or hand-written).
- [ ] Changelog/semver plan; tag first release after example `plan`/smoke tests documented.
- [ ] Verify: Docs reference real inputs/outputs; walkthrough commands executed once to ensure no typos.
