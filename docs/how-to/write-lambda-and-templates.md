# Write a Custom Lambda and Jinja Templates

When you create a custom LambdaCron task, you also need to create Jinja templates for whatever notification channel you're using. The main idea is that your function returns a dictionary mapping a result type to a payload. Your notification channel will respond to a specific result type, and the payload will be rendered by Jinja templates to create the final notification content.

## When to Use

* You are creating a custom LambdaCron task
* You want to customize the template of your notifications

## Goal

* Write Python task code that returns LambdaCron-compatible results.
* Write Jinja templates that render those result fields for print/email notifications.

## 1. Write a Task That Returns `result_type -> payload`

Your task class should extend `CronLambdaTask` and implement `_perform_task`.

```python
from lambdacron.lambda_task import CronLambdaTask


class ExampleTask(CronLambdaTask):
    def _perform_task(self, event, context):
        return {"example": {"message": "Hello World"}}


task = ExampleTask()
handler = task.lambda_handler
```

Based on `examples/basic/lambda/lambda_module.py`:

* Key (`example`) is the `result_type`.
* Value (`{"message": "Hello World"}`) is the payload rendered by templates.
* LambdaCron adds `result_type` to the published message body when it sends the payload to SNS, so you can access it in templates as `{{ result_type }}`.

## 2. Create templates that use the payload fields

How many templates you need depends on your notification channel. The print notifier only needs one template, while SES email notifications use three (subject, body text, body HTML). Each template can access the payload fields returned by your task.

```jinja
Example result: {{ message }}
```

You can use a more complicated template if your payload is more complex. For example, if your task returns a list, your template can iterate over it. For example, let's say your task returns a payload like this:

```python
{
  "SUCCESS": {
    "tasks": [
      {"id": 1, "name": "Task 1"},
      {"id": 2, "name": "Task 2"}
    ]
  },
  "FAILURE": {
    "tasks": [
      {"id": 3, "name": "Task 3"}
    ]
  }
}
```

Then you use that structured data in your template:

```jinja
<h2>Report for {{ result_type }}</h2>
{% if tasks %}
<p>Tasks ({{ tasks | length }}):</p>
<ul>
  {% for task in tasks %}
  <li>
    <strong>Task ID {{ task.id }}</strong> :: {{ task.name }}<br />
  </li>
  {% endfor %}
</ul>
{% else %}
<p>No tasks reported for this status.</p>
{% endif %}
```

## 3. Understand How Code Output Becomes Template Variables

At runtime:

1. `_perform_task` returns `{"result_type": payload}` entries.
2. LambdaCron publishes one SNS message per entry, with `result_type` in message attributes.
3. Notification handlers parse the JSON payload.
4. Handlers render templates with `jinja_template.render(**payload)`.

Important detail:

* `result_type` is injected into the message body by the publisher before it reaches the notifier.
* The SNS message attribute still carries the same `result_type`. It is used for filter policies and validation.
* That is why templates like `{{ result_type }}` work even when your `_perform_task` payload does not explicitly include a `result_type` field.

## 4. Checklist Before Deploying

* Ensure payload values are JSON-serializable.
* Ensure template variables exactly match payload field names.
* Keep templates strict: missing fields will fail rendering (LambdaCron uses strict Jinja undefined behavior).

## 5. Tip for Debugging Templates

You can test your templates using the `lambdacron.render` module, which takes in the output of your `_perform_task` and renders it with a template (for a given result type).


If you set up your lambda with a main guard that runs `_perform_task` and prints its output, you can see the templated results with:

```bash
python my_lambda.py | python -m lambdacron.render -t my_template.jinja --result-type example
```
