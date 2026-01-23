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
    load_sns_topic_arn,
)


def test_extract_context_metadata_handles_missing_attrs():
    context = SimpleNamespace(aws_request_id="req-123")
    metadata = extract_context_metadata(context)
    assert metadata == {"aws_request_id": "req-123", "function_name": None}


def test_load_sns_topic_arn_reads_env(monkeypatch):
    monkeypatch.setenv("SNS_TOPIC_ARN", "arn:one")
    assert load_sns_topic_arn() == "arn:one"


def test_load_sns_topic_arn_requires_value(monkeypatch):
    monkeypatch.delenv("SNS_TOPIC_ARN", raising=False)
    with pytest.raises(ValueError, match="SNS_TOPIC_ARN must be set"):
        load_sns_topic_arn()


def test_load_sns_message_group_id_default(monkeypatch):
    monkeypatch.delenv("SNS_MESSAGE_GROUP_ID", raising=False)
    assert load_sns_message_group_id() == "cloudcron"


def test_load_sns_message_group_id_override(monkeypatch):
    monkeypatch.setenv("SNS_MESSAGE_GROUP_ID", "custom-group")
    assert load_sns_message_group_id() == "custom-group"


def test_dispatch_sns_messages_publishes(caplog):
    sns_client = Mock()
    logger = logging.getLogger("test_dispatch")
    result = {"success": {"ok": True}, "failure": {"ok": False}}
    sns_topic_arn = "arn:one"

    with caplog.at_level(logging.INFO):
        dispatch_sns_messages(
            result=result,
            sns_topic_arn=sns_topic_arn,
            sns_client=sns_client,
            logger=logger,
        )

    sns_client.publish.assert_any_call(
        TopicArn="arn:one",
        Message=json.dumps({"ok": True}),
        Subject="Notification for success",
        MessageAttributes={
            "result_type": {"DataType": "String", "StringValue": "success"}
        },
        MessageGroupId="cloudcron",
    )
    sns_client.publish.assert_any_call(
        TopicArn="arn:one",
        Message=json.dumps({"ok": False}),
        Subject="Notification for failure",
        MessageAttributes={
            "result_type": {"DataType": "String", "StringValue": "failure"}
        },
        MessageGroupId="cloudcron",
    )


def test_cron_lambda_task_invokes_dispatch(caplog):
    sns_client = Mock()
    logger = logging.getLogger("test_task")

    class SampleTask(CronLambdaTask):
        def _perform_task(self, event, context):
            return {"success": {"ok": True}}

    task = SampleTask(
        sns_topic_arn="arn:one",
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
        MessageAttributes={
            "result_type": {"DataType": "String", "StringValue": "success"}
        },
        MessageGroupId="cloudcron",
    )


def test_cron_lambda_task_init_loads_sns_topic_arn(monkeypatch):
    monkeypatch.setenv("SNS_TOPIC_ARN", "arn:one")

    class SampleTask(CronLambdaTask):
        def _perform_task(self, event, context):
            return {"success": {"ok": True}}

    task = SampleTask(sns_client=Mock())
    assert task.sns_topic_arn == "arn:one"


def test_cron_lambda_task_init_creates_client_when_missing():
    session = Mock()
    sns_client = Mock()
    session.client.return_value = sns_client

    class SampleTask(CronLambdaTask):
        def _perform_task(self, event, context):
            return {}

    task = SampleTask(sns_topic_arn="arn:one", session=session)

    session.client.assert_called_once_with("sns")
    assert task.sns_client is sns_client
