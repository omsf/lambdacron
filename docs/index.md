# LambdaCron

## Welcome
LambdaCron is a Python library and Terraform module set for running scheduled tasks on AWS, with optional notifications.

At a high level, it helps teams package a task as a Lambda container image, schedule it with EventBridge, and route results through SNS to one or more notification channels.

The project is built around "infrastructure apps": reusable IaC packages that solve a specific operational need and can be deployed into any AWS account. LambdaCron aims to make it easy to create and share an ecosystem of these apps.

- Start building with [Tutorials](tutorials/quickstart.md)
- Solve specific tasks with [How-to guides](how-to/build-lambda-image.md)
- Check module contracts in [Reference](reference/terraform-modules.md)
- Understand design tradeoffs in [Explanation](explanation/architecture.md)

## Quickstart
Follow the [Quickstart](tutorials/quickstart.md) to deploy a scheduled Lambda and a notification path end to end.

## What You Can Build
- Scheduled Lambda-based jobs that publish typed results to a shared SNS topic.
- Optional notification channels (print, email, SMS) that subscribe by `result_type`.
- Publicly distributed task images: task authors can publish to public ECR, and users can republish those images into private ECR in their own accounts before deploying.
- Privately distributed task images: task authors can build and publish private ECR images directly and use those as the Lambda runtime.
- Infrastructure apps: a task image plus minimal Terraform wiring that others can "install" in their own AWS environments.

## Status
- Note that modules and handlers are evolving
