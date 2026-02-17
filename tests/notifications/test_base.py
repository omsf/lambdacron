import json
import logging

import pytest

from lambdacron.notifications.base import (
    EnvVarTemplateProvider,
    RenderedTemplateNotificationHandler,
)


class CapturingHandler(RenderedTemplateNotificationHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.calls = []

    def notify(self, *, result, rendered, record):
        self.calls.append({"result": result, "rendered": rendered, "record": record})


def build_sqs_event(
    body,
    *,
    event_source="aws:sqs",
    event_source_arn=None,
    message_attributes=None,
    message_id="msg-123",
):
    record = {
        "body": body,
        "eventSource": event_source,
        "messageId": message_id,
    }
    if event_source_arn:
        record["eventSourceARN"] = event_source_arn
    if message_attributes is not None:
        record["messageAttributes"] = message_attributes
    return {"Records": [record]}


def test_env_var_template_provider_reads_template(monkeypatch):
    monkeypatch.setenv("TEMPLATE", "Hello {{ name }}")
    provider = EnvVarTemplateProvider()
    assert provider.get_template() == "Hello {{ name }}"


def test_env_var_template_provider_requires_value(monkeypatch):
    monkeypatch.delenv("TEMPLATE", raising=False)
    provider = EnvVarTemplateProvider()
    with pytest.raises(ValueError, match="TEMPLATE must be set"):
        provider.get_template()


def test_notification_handler_parses_sqs_json_body(monkeypatch):
    monkeypatch.setenv("TEMPLATE", "Status {{ status }}")
    handler = CapturingHandler(template_providers={"body": EnvVarTemplateProvider()})
    event = build_sqs_event(json.dumps({"status": "ok"}))

    response = handler.lambda_handler(event, context=None)

    assert handler.calls == [
        {
            "result": {"status": "ok"},
            "rendered": {"body": "Status ok"},
            "record": event["Records"][0],
        }
    ]
    assert response == {"batchItemFailures": []}


def test_notification_handler_parses_sns_envelope(monkeypatch):
    monkeypatch.setenv("TEMPLATE", "Result {{ status }}")
    handler = CapturingHandler(template_providers={"body": EnvVarTemplateProvider()})
    sns_body = json.dumps({"Message": json.dumps({"status": "good"})})
    event = build_sqs_event(sns_body)

    response = handler.lambda_handler(event, context=None)

    assert handler.calls[0]["rendered"]["body"] == "Result good"
    assert response == {"batchItemFailures": []}


def test_notification_handler_rejects_wrong_event_source(monkeypatch):
    monkeypatch.setenv("TEMPLATE", "Hello {{ name }}")
    handler = CapturingHandler(template_providers={"body": EnvVarTemplateProvider()})
    event = build_sqs_event(json.dumps({"name": "Ada"}), event_source="aws:s3")

    response = handler.lambda_handler(event, context=None)

    assert response == {"batchItemFailures": [{"itemIdentifier": "msg-123"}]}


def test_notification_handler_validates_queue_arn(monkeypatch):
    monkeypatch.setenv("TEMPLATE", "Hello {{ name }}")
    handler = CapturingHandler(
        template_providers={"body": EnvVarTemplateProvider()},
        expected_queue_arn="arn:aws:sqs:us-east-1:123:queue",
    )
    event = build_sqs_event(
        json.dumps({"name": "Ada"}),
        event_source_arn="arn:aws:sqs:us-east-1:123:other",
    )

    response = handler.lambda_handler(event, context=None)

    assert response == {"batchItemFailures": [{"itemIdentifier": "msg-123"}]}


def test_notification_handler_raises_on_missing_template_vars(monkeypatch):
    monkeypatch.setenv("TEMPLATE", "Hello {{ name }}")
    handler = CapturingHandler(template_providers={"body": EnvVarTemplateProvider()})
    event = build_sqs_event(json.dumps({"status": "ok"}))

    response = handler.lambda_handler(event, context=None)

    assert response == {"batchItemFailures": [{"itemIdentifier": "msg-123"}]}


def test_notification_handler_logs_invocation(monkeypatch, caplog):
    monkeypatch.setenv("TEMPLATE", "Hello {{ name }}")
    handler = CapturingHandler(
        template_providers={"body": EnvVarTemplateProvider()},
        logger=logging.getLogger("test_notifications"),
    )
    event = {
        "Records": [
            {"body": json.dumps({"name": "Ada"}), "eventSource": "aws:sqs"},
            {"body": json.dumps({"name": "Grace"}), "eventSource": "aws:sqs"},
        ]
    }

    with caplog.at_level(logging.INFO):
        handler.lambda_handler(event, context=None)

    assert any(record.message == "notification_invocation" for record in caplog.records)


def test_parse_result_rejects_missing_body(monkeypatch):
    monkeypatch.setenv("TEMPLATE", "Hello {{ name }}")
    handler = CapturingHandler(template_providers={"body": EnvVarTemplateProvider()})
    event = {"Records": [{"eventSource": "aws:sqs", "messageId": "msg-123"}]}

    response = handler.lambda_handler(event, context=None)

    assert response == {"batchItemFailures": [{"itemIdentifier": "msg-123"}]}


def test_parse_result_rejects_invalid_json_body(monkeypatch):
    monkeypatch.setenv("TEMPLATE", "Hello {{ name }}")
    handler = CapturingHandler(template_providers={"body": EnvVarTemplateProvider()})
    event = build_sqs_event("{bad")

    response = handler.lambda_handler(event, context=None)

    assert response == {"batchItemFailures": [{"itemIdentifier": "msg-123"}]}


def test_parse_result_rejects_non_string_sns_message(monkeypatch):
    monkeypatch.setenv("TEMPLATE", "Hello {{ name }}")
    handler = CapturingHandler(template_providers={"body": EnvVarTemplateProvider()})
    body = json.dumps({"Message": {"status": "ok"}})
    event = build_sqs_event(body)

    response = handler.lambda_handler(event, context=None)

    assert response == {"batchItemFailures": [{"itemIdentifier": "msg-123"}]}


def test_parse_result_rejects_invalid_sns_message_json(monkeypatch):
    monkeypatch.setenv("TEMPLATE", "Hello {{ name }}")
    handler = CapturingHandler(template_providers={"body": EnvVarTemplateProvider()})
    body = json.dumps({"Message": "{bad"})
    event = build_sqs_event(body)

    response = handler.lambda_handler(event, context=None)

    assert response == {"batchItemFailures": [{"itemIdentifier": "msg-123"}]}


def test_parse_result_rejects_non_object_payload(monkeypatch):
    monkeypatch.setenv("TEMPLATE", "Hello {{ name }}")
    handler = CapturingHandler(template_providers={"body": EnvVarTemplateProvider()})
    event = build_sqs_event(json.dumps(["not", "an", "object"]))

    response = handler.lambda_handler(event, context=None)

    assert response == {"batchItemFailures": [{"itemIdentifier": "msg-123"}]}


@pytest.mark.parametrize("include_result_type", [True, False])
@pytest.mark.parametrize("payload_has_result_type", [True, False])
def test_notification_handler_result_type_injection(
    monkeypatch, include_result_type, payload_has_result_type
):
    monkeypatch.setenv("TEMPLATE", "Result {{ result_type | default('none') }}")
    handler = CapturingHandler(
        template_providers={"body": EnvVarTemplateProvider()},
        include_result_type=include_result_type,
    )
    payload = {"status": "ok"}
    if payload_has_result_type:
        payload["result_type"] = "payload"
    event = build_sqs_event(
        json.dumps(payload),
        message_attributes={"result_type": {"stringValue": "attribute"}},
    )

    handler.lambda_handler(event, context=None)

    result = handler.calls[0]["result"]
    if payload_has_result_type:
        assert result["result_type"] == "payload"
    elif include_result_type:
        assert result["result_type"] == "attribute"
    else:
        assert "result_type" not in result
