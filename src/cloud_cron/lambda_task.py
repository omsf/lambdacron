import json
import logging
import os
from abc import ABC, abstractmethod
from typing import Any, Mapping, Optional

import boto3
from botocore.client import BaseClient


class CronLambdaTask(ABC):
    """
    Base class for scheduled Lambda tasks.

    Parameters
    ----------
    sns_topics : Mapping[str, str], optional
        Mapping of topic keys to SNS topic ARNs. Defaults to loading from
        the ``SNS_TOPICS`` environment variable.
    sns_client : botocore.client.BaseClient, optional
        Preconfigured SNS client. If omitted, a client is created from the
        provided session.
    session : boto3.session.Session, optional
        Session used to create the SNS client when one is not provided.
    logger : logging.Logger, optional
        Logger used for structured logging. Defaults to a class-named logger.

    Attributes
    ----------
    sns_topics : dict[str, str]
        A dictionary mapping SNS topic names to their ARNs.

    """

    def __init__(
        self,
        *,
        sns_topics: Optional[Mapping[str, str]] = None,
        sns_client: Optional[BaseClient] = None,
        session: Optional[boto3.session.Session] = None,
        logger: Optional[logging.Logger] = None,
    ) -> None:
        if sns_topics is None:
            sns_topics = load_sns_topics()
        self.sns_topics = dict(sns_topics)
        if sns_client is None:
            session = session or boto3.session.Session()
            sns_client = session.client("sns")
        self.sns_client = sns_client
        self.logger = logger or logging.getLogger(self.__class__.__name__)

    def lambda_handler(self, event: Any, context: Any) -> None:
        """
        This method is the entry point for the Lambda function.
        It processes the event and context parameters.

        Parameters
        ----------
        event : Any
            Event payload passed to the Lambda.
        context : Any
            Lambda context object.
        """
        self.logger.info(
            "lambda_invocation",
            extra={"event": event, "context": extract_context_metadata(context)},
        )

        result = self._perform_task(event, context)
        dispatch_sns_messages(
            result=result,
            sns_topics=self.sns_topics,
            sns_client=self.sns_client,
            logger=self.logger,
        )

    @abstractmethod
    def _perform_task(self, event: Any, context: Any) -> dict[str, Any]:
        """
        This should return a dictionary where each key corresponds to a key
        from the sns_topics dictionary, and the value is the message to be
        sent to that SNS topic as a JSON serializable object.

        Parameters
        ----------
        event : Any
            Event payload passed to the Lambda.
        context : Any
            Lambda context object.

        Returns
        -------
        dict[str, Any]
            Mapping of topic keys to JSON-serializable payloads.
        """
        raise NotImplementedError("Subclasses must implement this method.")


def extract_context_metadata(context: Any) -> dict[str, Optional[str]]:
    """
    Extract structured metadata from a Lambda context object.

    Parameters
    ----------
    context : Any
        Lambda context object passed to the handler.

    Returns
    -------
    dict[str, Optional[str]]
        Dictionary of relevant metadata fields.
    """
    return {
        "aws_request_id": getattr(context, "aws_request_id", None),
        "function_name": getattr(context, "function_name", None),
    }


def load_sns_topics(env_var: str = "SNS_TOPICS") -> dict[str, str]:
    """
    Load SNS topics from a JSON environment variable.

    Parameters
    ----------
    env_var : str, optional
        Environment variable name containing a JSON object.

    Returns
    -------
    dict[str, str]
        Mapping of topic keys to SNS topic ARNs.

    Raises
    ------
    ValueError
        If the environment variable is missing or not a JSON mapping of strings.
    """
    sns_topics_json = os.environ.get(env_var, "{}")
    try:
        raw = json.loads(sns_topics_json)
    except json.JSONDecodeError as exc:
        raise ValueError(f"{env_var} must be valid JSON") from exc
    if not isinstance(raw, dict) or not all(
        isinstance(key, str) and isinstance(value, str) for key, value in raw.items()
    ):
        raise ValueError(
            f"{env_var} must be a JSON object of string keys to string ARNs"
        )
    return raw


def load_sns_message_group_id(env_var: str = "SNS_MESSAGE_GROUP_ID") -> str:
    """
    Load the SNS FIFO message group ID from the environment.

    Parameters
    ----------
    env_var : str, optional
        Environment variable name containing the group ID.

    Returns
    -------
    str
        Message group ID for FIFO SNS topics.
    """
    return os.environ.get(env_var, "cloudcron")


def validate_sns_result(
    result: Mapping[str, Any], sns_topics: Mapping[str, str]
) -> None:
    """
    Validate that results align with configured SNS topic keys.

    Parameters
    ----------
    result : Mapping[str, Any]
        Mapping of topic keys to payloads returned by the task.
    sns_topics : Mapping[str, str]
        Mapping of topic keys to SNS topic ARNs.

    Raises
    ------
    ValueError
        If the result contains unknown topic keys.
    """
    result_keys = set(result.keys())
    topic_keys = set(sns_topics.keys())
    unknown_topics = result_keys - topic_keys
    if unknown_topics:
        raise ValueError(
            f"SNS topic mismatch (unknown topic keys: {sorted(unknown_topics)})"
        )


def dispatch_sns_messages(
    *,
    result: Mapping[str, Any],
    sns_topics: Mapping[str, str],
    sns_client: BaseClient,
    logger: logging.Logger,
) -> None:
    """
    Dispatches a message to all configured SNS topics.

    Parameters
    ----------
    result : Mapping[str, Any]
        Mapping of topic keys to message payloads.
    sns_topics : Mapping[str, str]
        Mapping of topic keys to SNS topic ARNs.
    sns_client : botocore.client.BaseClient
        SNS client used to publish messages.
    logger : logging.Logger
        Logger used to emit structured publish logs.
    """
    validate_sns_result(result, sns_topics)
    for topic_name, message in result.items():
        topic_arn = sns_topics[topic_name]
        sns_client.publish(
            TopicArn=topic_arn,
            Message=json.dumps(message),
            Subject=f"Notification for {topic_name}",
            MessageGroupId=load_sns_message_group_id(),
        )
        logger.info(
            "sns_publish",
            extra={"topic_name": topic_name, "topic_arn": topic_arn},
        )
