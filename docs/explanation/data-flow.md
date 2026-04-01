# Data Flow: `_perform_task` to Rendered Notification

This page traces the data flow from a scheduled task's `_perform_task` return value through SNS publication, SQS subscription, notifier parsing, and final template rendering. It illustrates how the shape of the data evolves at each stage and how it interacts with filter policies and message attributes.

## Scenario

Assume one scheduled task publishes into one shared SNS topic, and two notifiers are subscribed with filter policies:

* Print notifier queue: `result_types = ["OK"]`
* Email notifier queue: `result_types = ["ERROR"]`

## Phase 1: `_perform_task` Return Value

Let's say the lambda runs a few tasks, which either pass (status `OK`) or fail (status `ERROR`). Let's say that the task-specific information to be used in the templates are `taskid` and `name`. Here's an example of what the return value of `_perform_task` might look like:

```json
{
  "OK": {
    "tasks": [{"taskid": 1, "name": "Foo"}, {"taskid": 2, "name": "Bar"}]
  },
  "ERROR": {
    "tasks": [{"taskid": 3, "name": "Baz"}]
  }
}
```

## Phase 2: What Gets Published to SNS

We publish one SNS message per status type, so in this case two messages: one for `OK` and one for `ERROR`. Each message includes the relevant portion of the `_perform_task` return value, with a top-level `result_type` added before publication. The same `result_type` is also included as a `MessageAttribute` to allow for filtering by the SQS subscriptions.

For `OK`, the publish call payload shape is:

```json
{
  "TopicArn": "arn:aws:sns:us-east-1:123456789012:lambdacron-results.fifo",
  "Message": "{\"tasks\": [{\"taskid\": 1, \"name\": \"Foo\"}, {\"taskid\": 2, \"name\": \"Bar\"}], \"result_type\": \"OK\"}",
  "Subject": "Notification for OK",
  "MessageAttributes": {
    "result_type": {
      "DataType": "String",
      "StringValue": "OK"
    }
  },
  "MessageGroupId": "lambdacron"
}
```

For `ERROR`, the shape is identical except:

- `Message` is `"{\"tasks\": [{\"taskid\": 3, \"name\": \"Baz\"}], \"result_type\": \"ERROR\"}"`
- `Subject` is `"Notification for ERROR"`
- `MessageAttributes.result_type.StringValue` is `"ERROR"`

## Phase 3: What Arrives in Each SQS Queue

Because subscriptions filter on `MessageAttributes.result_type`, each queue receives only matching messages. From here, we'll just follow the message for `OK`; the message for `ERROR` has the same shape but different content (and a different template rendering result in the end).

The SQS event record (as seen by notifier Lambda) looks like:

```json
{
  "Records": [
    {
      "messageId": "msg-ok-1",
      "eventSource": "aws:sqs",
      "body": "{\"tasks\": [{\"taskid\": 1, \"name\": \"Foo\"}, {\"taskid\": 2, \"name\": \"Bar\"}], \"result_type\": \"OK\"}",
      "messageAttributes": {
        "result_type": {
          "stringValue": "OK",
          "dataType": "String"
        }
      }
    }
  ]
}
```

## Phase 4: Notifier Parse Behavior with This Shape

The notifier parser converts the JSON string back into an object and validates that the payload `result_type` matches the SQS `messageAttributes.result_type` value when that attribute is present.
The result, which is fed to the notifier's templates, is:

```json
{
  "tasks": [{"taskid": 1, "name": "Foo"}, {"taskid": 2, "name": "Bar"}],
  "result_type": "OK"
}
```

## Phase 5: Template Rendering

Let's say the template used by the print notifier for `OK` messages is:

```jinja2
Result {{ result_type }}: {% for task in tasks %}#{{ task.taskid }} {{ task.name }}{% if not loop.last %}, {% endif %}{% endfor %}
```

The output for the `OK` message would be:

```text
Result OK: #1 Foo, #2 Bar
```
