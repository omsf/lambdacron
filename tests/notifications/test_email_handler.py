import json

from botocore.exceptions import ClientError

from lambdacron.notifications.base import EnvVarTemplateProvider
from lambdacron.notifications.email_handler import EmailNotificationHandler


class FakeSesClient:
    def __init__(self) -> None:
        self.calls = []

    def send_email(self, **kwargs):
        self.calls.append(kwargs)
        return {"MessageId": "msg-123"}


def build_sqs_event(payload, *, message_id="msg-123"):
    return {
        "Records": [
            {
                "body": json.dumps(payload),
                "eventSource": "aws:sqs",
                "messageId": message_id,
            },
        ]
    }


def test_email_handler_sends_rendered_templates(monkeypatch):
    monkeypatch.setenv("EMAIL_SUBJECT_TEMPLATE", "Hello {{ name }}")
    monkeypatch.setenv("EMAIL_TEXT_TEMPLATE", "Text for {{ name }}")
    monkeypatch.setenv("EMAIL_HTML_TEMPLATE", "<p>{{ name }}</p>")
    ses_client = FakeSesClient()
    handler = EmailNotificationHandler(
        subject_template_provider=EnvVarTemplateProvider("EMAIL_SUBJECT_TEMPLATE"),
        text_template_provider=EnvVarTemplateProvider("EMAIL_TEXT_TEMPLATE"),
        html_template_provider=EnvVarTemplateProvider("EMAIL_HTML_TEMPLATE"),
        sender="sender@example.com",
        recipients=["alice@example.com", "bob@example.com"],
        ses_client=ses_client,
    )
    event = build_sqs_event({"name": "Ada"})

    handler.lambda_handler(event, context=None)

    assert len(ses_client.calls) == 1
    call = ses_client.calls[0]
    assert call["Source"] == "sender@example.com"
    assert call["Destination"]["ToAddresses"] == [
        "alice@example.com",
        "bob@example.com",
    ]
    assert call["Message"]["Subject"]["Data"] == "Hello Ada"
    assert call["Message"]["Body"]["Text"]["Data"] == "Text for Ada"
    assert call["Message"]["Body"]["Html"]["Data"] == "<p>Ada</p>"


def test_email_handler_includes_optional_fields(monkeypatch):
    monkeypatch.setenv("EMAIL_SUBJECT_TEMPLATE", "Subject {{ name }}")
    monkeypatch.setenv("EMAIL_TEXT_TEMPLATE", "Text {{ name }}")
    monkeypatch.setenv("EMAIL_HTML_TEMPLATE", "<p>{{ name }}</p>")
    ses_client = FakeSesClient()
    handler = EmailNotificationHandler(
        subject_template_provider=EnvVarTemplateProvider("EMAIL_SUBJECT_TEMPLATE"),
        text_template_provider=EnvVarTemplateProvider("EMAIL_TEXT_TEMPLATE"),
        html_template_provider=EnvVarTemplateProvider("EMAIL_HTML_TEMPLATE"),
        sender="sender@example.com",
        recipients=["ops@example.com"],
        ses_client=ses_client,
        config_set="alerts",
        reply_to=["reply@example.com"],
    )
    event = build_sqs_event({"name": "Grace"})

    handler.lambda_handler(event, context=None)

    call = ses_client.calls[0]
    assert call["ConfigurationSetName"] == "alerts"
    assert call["ReplyToAddresses"] == ["reply@example.com"]


def test_email_handler_reports_ses_error(monkeypatch):
    monkeypatch.setenv("EMAIL_SUBJECT_TEMPLATE", "Subject {{ name }}")
    monkeypatch.setenv("EMAIL_TEXT_TEMPLATE", "Text {{ name }}")
    monkeypatch.setenv("EMAIL_HTML_TEMPLATE", "<p>{{ name }}</p>")

    error_response = {
        "Error": {"Code": "MessageRejected", "Message": "Not verified"},
        "ResponseMetadata": {"RequestId": "req-123", "HTTPStatusCode": 400},
    }

    class ErrorSesClient:
        def send_email(self, **kwargs):
            raise ClientError(error_response, "SendEmail")

    handler = EmailNotificationHandler(
        subject_template_provider=EnvVarTemplateProvider("EMAIL_SUBJECT_TEMPLATE"),
        text_template_provider=EnvVarTemplateProvider("EMAIL_TEXT_TEMPLATE"),
        html_template_provider=EnvVarTemplateProvider("EMAIL_HTML_TEMPLATE"),
        sender="sender@example.com",
        recipients=["ops@example.com"],
        ses_client=ErrorSesClient(),
    )
    event = build_sqs_event({"name": "Ada"}, message_id="msg-err")

    response = handler.lambda_handler(event, context=None)

    assert response == {"batchItemFailures": [{"itemIdentifier": "msg-err"}]}
