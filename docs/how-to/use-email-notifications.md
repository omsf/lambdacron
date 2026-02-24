# Use Email Notifications

The LambdaCron root module creates the scheduled Lambda and shared SNS topic, but it does not create notification channels. Use `email-notification` to send selected `result_type` values through Amazon SES.

## When to Use
* You want SES email notifications for one or more LambdaCron `result_type` values.
* You already have, or can provide, a notification-handler container image.

## Before You Begin

* Complete SES setup in [Set Up SES Prerequisites](set-up-ses.md).
* Verify your SES sender identity in the same AWS region as your notifier Lambda.
* If your account is in SES sandbox mode, verify recipient addresses too.
* Create your subject/text/html template files.

## Inputs to Provide

* `sns_topic_arn` from your LambdaCron stack output.
* `lambda_image_uri` for the notification handler container.
* `fifo_queue_name` ending with `.fifo`.
* `sender`, `recipients`, and optional `reply_to`.
* `subject_template_file`, `text_template_file`, and `html_template_file`.
* Optional runtime/routing settings such as `result_types`, `lambda_name`, `batch_size`, and `tags`.

## Steps

### 1. Create email templates

The email notification module requires 3 Jinja templates: one for the email subject, one for the text-only body, and one for the HTML body.

```jinja
{# templates/email-subject.txt #}
[{{ result_type }}] LambdaCron notification
```

```jinja
{# templates/email-body.txt #}
Result type: {{ result_type }}
Message: {{ message }}
```

```html
<!-- templates/email-body.html -->
<h2>LambdaCron notification</h2>
<p><strong>Result type:</strong> {{ result_type }}</p>
<p><strong>Message:</strong> {{ message }}</p>
```

### 2. Republish the notification image or get the image URI

If you have already republished the notification handler image to your own ECR repository, you can skip this step. Otherwise, use the `lambda-image-republish` module to copy the public image to your account/region.

```hcl
module "notification_image_republish" {
  source = "../../modules/lambda-image-republish"

  source_lambda_repo = "public.ecr.aws/i9p4w7k9/lambdacron-notifications"
  source_lambda_tag  = "latest"
}
```

If you do this, you can wire in the lambda image URI from the module output as shown in the next step.

On the other hand, if you have your own notification handler image, you can provide the URI directly. To get that, you can find it in the ECR console or use the AWS CLI:

```bash
aws ecr describe-repositories --repository-names "your-repo-name" --query "repositories[0].repositoryUri" --output text
```


### 3. Add the `email-notification` module

You'll connect it to the LambdaCron SNS topic and provide the email settings and templates. You'll also select which result types to send email for. If you leave `result_types` empty or omit it, the notification handler will send emails for all result types. **You will get one email for each notification type**, this will not combine multiple notification types into a single email.

```hcl
module "email_notification" {
  source = "../../modules/email-notification"

  sns_topic_arn    = module.lambdacron.sns_topic_arn
  fifo_queue_name  = "lambdacron-email.fifo"
  lambda_image_uri = module.notification_image_republish.lambda_image_uri_with_digest

  result_types = ["example", "ERROR"]

  sender     = var.email_sender
  recipients = var.email_recipients
  reply_to   = var.email_reply_to

  subject_template_file = "${path.module}/templates/email-subject.txt"
  text_template_file    = "${path.module}/templates/email-body.txt"
  html_template_file    = "${path.module}/templates/email-body.html"

  tags = local.common_tags
}
```

### 4. Plan and apply

Here we use `tofu`, but you could also use `terraform`. This will deploy your infrastructure.

```bash
tofu plan
tofu apply
```

## Validation

There are two relatively easy ways you can trigger the email notification lambda:

1. [Deploy your LambdaCron with `create_test_url`](use-test-url.md) enabled and invoke the test URL.
2. Publish a test message with a `result_type` value included in `result_types`:

```bash
aws sns publish \
  --topic-arn "$(tofu output -raw sns_topic_arn)" \
  --message '{"message":"Email notification smoke test"}' \
  --message-attributes '{"result_type":{"DataType":"String","StringValue":"example"}}' \
  --message-group-id "email-smoke-test"
```

Note that the test URL won't create an email unless the result creates a message with a `result_type` value included in in your notifier's `result_types` list.

If you receive the email, then it was successful!

If not, here are some troubleshooting tips:

* Check the CloudWatch logs for the notifier Lambda for any errors. In particular, it might complain if you aren't allowed to send email (see setup instructions in [Set Up SES Prerequisites](set-up-ses.md)).
* If using the test URL, check the CloudWatch logs for the scheduled Lambda to confirm that it is working.
* If you don't see logs in the CloudWatch logs for your lambdas, check the Lambda console to confirm that the Lambda was created successfully and that it has the correct triggers.
