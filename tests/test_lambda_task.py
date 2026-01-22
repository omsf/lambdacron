import json
import logging
from types import SimpleNamespace
from unittest.mock import Mock

import pytest

from cloud_cron.lambda_task import (
    CronLambdaTask,
    dispatch_sns_messages,
    extract_context_metadata,
    load_sns_message_group_id,
    load_sns_topics,
    validate_sns_result,
)


def test_extract_context_metadata_handles_missing_attrs():
    context = SimpleNamespace(aws_request_id="req-123")
    metadata = extract_context_metadata(context)
    assert metadata == {"aws_request_id": "req-123", "function_name": None}


def test_load_sns_topics_valid_json(monkeypatch):
    monkeypatch.setenv("SNS_TOPICS", json.dumps({"success": "arn:one"}))
    assert load_sns_topics() == {"success": "arn:one"}


def test_load_sns_topics_invalid_json(monkeypatch):
    monkeypatch.setenv("SNS_TOPICS", "{bad")
    with pytest.raises(ValueError, match="SNS_TOPICS must be valid JSON"):
        load_sns_topics()


def test_load_sns_topics_invalid_mapping(monkeypatch):
    monkeypatch.setenv("SNS_TOPICS", json.dumps({"ok": 123}))
    with pytest.raises(ValueError, match="SNS_TOPICS must be a JSON object"):
        load_sns_topics()


def test_load_sns_message_group_id_default(monkeypatch):
    monkeypatch.delenv("SNS_MESSAGE_GROUP_ID", raising=False)
    assert load_sns_message_group_id() == "cloudcron"


def test_load_sns_message_group_id_override(monkeypatch):
    monkeypatch.setenv("SNS_MESSAGE_GROUP_ID", "custom-group")
    assert load_sns_message_group_id() == "custom-group"


def test_validate_sns_result_allows_subset():
    sns_topics = {"success": "arn:one", "failure": "arn:two"}
    result = {"success": {"ok": True}}
    validate_sns_result(result, sns_topics)


def test_validate_sns_result_rejects_unknown():
    sns_topics = {"success": "arn:one"}
    result = {"unknown": {"ok": True}}
    with pytest.raises(ValueError, match="unknown topic keys"):
        validate_sns_result(result, sns_topics)


def test_dispatch_sns_messages_publishes(caplog):
    sns_client = Mock()
    logger = logging.getLogger("test_dispatch")
    result = {"success": {"ok": True}, "failure": {"ok": False}}
    sns_topics = {"success": "arn:one", "failure": "arn:two"}

    with caplog.at_level(logging.INFO):
        dispatch_sns_messages(
            result=result,
            sns_topics=sns_topics,
            sns_client=sns_client,
            logger=logger,
        )

    sns_client.publish.assert_any_call(
        TopicArn="arn:one",
        Message=json.dumps({"ok": True}),
        Subject="Notification for success",
        MessageGroupId="cloudcron",
    )
    sns_client.publish.assert_any_call(
        TopicArn="arn:two",
        Message=json.dumps({"ok": False}),
        Subject="Notification for failure",
        MessageGroupId="cloudcron",
    )


def test_cron_lambda_task_invokes_dispatch(caplog):
    sns_client = Mock()
    logger = logging.getLogger("test_task")

    class SampleTask(CronLambdaTask):
        def _perform_task(self, event, context):
            return {"success": {"ok": True}}

    task = SampleTask(
        sns_topics={"success": "arn:one"},
        sns_client=sns_client,
        logger=logger,
    )
    context = SimpleNamespace(aws_request_id="req-1", function_name="fn")

    with caplog.at_level(logging.INFO):
        task.lambda_handler({"sample": True}, context)

    sns_client.publish.assert_called_once_with(
        TopicArn="arn:one",
        Message=json.dumps({"ok": True}),
        Subject="Notification for success",
        MessageGroupId="cloudcron",
    )


def test_cron_lambda_task_init_loads_sns_topics(monkeypatch):
    monkeypatch.setenv("SNS_TOPICS", json.dumps({"success": "arn:one"}))

    class SampleTask(CronLambdaTask):
        def _perform_task(self, event, context):
            return {"success": {"ok": True}}

    task = SampleTask(sns_client=Mock())
    assert task.sns_topics == {"success": "arn:one"}


def test_cron_lambda_task_init_creates_client_when_missing():
    session = Mock()
    sns_client = Mock()
    session.client.return_value = sns_client

    class SampleTask(CronLambdaTask):
        def _perform_task(self, event, context):
            return {}

    task = SampleTask(sns_topics={"success": "arn:one"}, session=session)

    session.client.assert_called_once_with("sns")
    assert task.sns_client is sns_client
