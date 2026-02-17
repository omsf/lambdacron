import json
from lambdacron.notifications.base import EnvVarTemplateProvider
from lambdacron.notifications.print_handler import PrintNotificationHandler


def test_print_handler_prints_rendered_template(monkeypatch, capsys):
    monkeypatch.setenv("TEMPLATE", "Hello {{ name }}")
    handler = PrintNotificationHandler(template_provider=EnvVarTemplateProvider())
    event = {
        "Records": [{"body": json.dumps({"name": "Ada"}), "eventSource": "aws:sqs"}]
    }

    handler.lambda_handler(event, context=None)

    captured = capsys.readouterr()
    assert captured.out.strip() == "Hello Ada"
