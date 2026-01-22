# Cloud Cron

The idea here is to create tooling to run scheduled tasks in a cloud environment, similar to cron jobs on Unix systems.

This is intended to be a framework that can be used by client code to define the tasks and the notification channels for those tasks.

## Components

1. **Scheduled Lambda Functions**: The goal here is that the client can provide their own lambda function (as a container image) and, from that, we will run it on a schedule defined by the client. The lambda function needs to know 1 or more SNS topics to which it will publish messages when it runs; different "types" of messages can go to different SNS topics, which will then be subscribed to by different notification channels. This will include the lambda execution role and the scheduled events.
2. **SNS Topics**: These will be manually created by the client code, but ARNs might be needed to give the lambda permissions to publish.
3. **Notification Channels**: We will provide modules for different notification channels (e.g., email via SES, SMS via Twilio, etc.). Each notification module owns the SNS->SQS->Lambda wiring: it provisions the FIFO SQS queue/subscription used for deduplication and triggers its handler; the user should not create that queue manually. Each channel ships its own container image (build or republish) that renders a Jinja2 template and delivers via its notifier.
4. **Lambda Image Utilities**: In addition to republishing an existing Lambda container, we will provide a module to build an image from a local directory containing a Dockerfile and publish it to ECR for use by the scheduled-lambda module.
5. **Python Runtime Library**: Provide reusable Python code in `src/cloud_cron/` that makes authoring custom scheduled lambdas easy (task base class, SNS dispatch helpers, and ergonomic handler wiring). This includes a template provider abstraction so notification handlers can source templates from env vars, URLs, or S3.


The goal is that the user will need to:

1. Write a lambda function that publishes to the desired SNS topics (provided as envionment variables).
2. Write a small terraform module that looks something like:

```hcl
resource "aws_sns_topic" "example_topic" {
  name = "example-topic"
}

module "my_scheduled_lambda" {
  source = "./modules/scheduled-lambda"

  lambda_image_uri = "123456789012.dkr.ecr.us-west-2.amazonaws.com/my-lambda:latest"
  schedule_expression = "rate(5 minutes)"
  sns_topic_arns = {
    example = aws_sns_topic.example_topic.arn
  }
}

module "my_email_notification" {
  source = "./modules/email-notification"
  sns_topic_arn = aws_sns_topic.example_topic.arn
  template_file = "path/to/email/template.html"
  email_sender = "me@example.com"
  email_recipients = [
    "alice@example.com",
    "bob@example.com",
  ]
}
```

(There may be additional parameters needed, but this is the general idea.)

## Additional convenience

We should also provide a module that allows us to take an externally-defined lambda and redeploy it in a local environment. The idea is that the lambdas users use are served from their own accounts, and are copies of our official release lambdas.

Usage would look something like this:

```hcl
module my_lambda_container {
  source = "./modules/lambda-container"
  source_lambda_repo = "123456789012.dkr.ecr.us-west-2.amazonaws.com/my-lambda"
  source_lambda_tag = "latest"
}

module my_lambda_image_build {
  source = "./modules/lambda-image-build"
  source_dir = "${path.module}/lambda-src"
  repository_name = "my-lambda"
  image_tag = "latest"
}
```

Then the user could use the output of that module as the `lambda_image_uri` parameter to the scheduled lambda module.
