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
    sns_topic_arn : str, optional
        SNS topic ARN used for all published results. Defaults to loading from
        the ``SNS_TOPIC_ARN`` environment variable.
    sns_client : botocore.client.BaseClient, optional
        Preconfigured SNS client. If omitted, a client is created from the
        provided session.
    session : boto3.session.Session, optional
        Session used to create the SNS client when one is not provided.
    logger : logging.Logger, optional
        Logger used for structured logging. Defaults to a class-named logger.

    Attributes
    ----------
    sns_topic_arn : str
        SNS topic ARN used for all published results.

    """

    def __init__(
        self,
        *,
        sns_topic_arn: Optional[str] = None,
        sns_client: Optional[BaseClient] = None,
        session: Optional[boto3.session.Session] = None,
        logger: Optional[logging.Logger] = None,
    ) -> None:
        if sns_topic_arn is None:
            sns_topic_arn = load_sns_topic_arn()
        self.sns_topic_arn = sns_topic_arn
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
            sns_topic_arn=self.sns_topic_arn,
            sns_client=self.sns_client,
            logger=self.logger,
        )

    @abstractmethod
    def _perform_task(self, event: Any, context: Any) -> dict[str, Any]:
        """
        This should return a dictionary where each key corresponds to a
        result type, and the value is the message to be sent to SNS as a
        JSON serializable object.

        Parameters
        ----------
        event : Any
            Event payload passed to the Lambda.
        context : Any
            Lambda context object.

        Returns
        -------
        dict[str, Any]
            Mapping of result types to JSON-serializable payloads.
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


def load_sns_topic_arn(env_var: str = "SNS_TOPIC_ARN") -> str:
    """
    Load SNS topic ARN from the environment.

    Parameters
    ----------
    env_var : str, optional
        Environment variable name containing the SNS topic ARN.

    Returns
    -------
    str
        SNS topic ARN.

    Raises
    ------
    ValueError
        If the environment variable is missing or empty.
    """
    sns_topic_arn = os.environ.get(env_var)
    if not sns_topic_arn:
        raise ValueError(f"{env_var} must be set to an SNS topic ARN")
    return sns_topic_arn


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


def dispatch_sns_messages(
    *,
    result: Mapping[str, Any],
    sns_topic_arn: str,
    sns_client: BaseClient,
    logger: logging.Logger,
) -> None:
    """
    Publishes result messages to an SNS topic.

    Parameters
    ----------
    result : Mapping[str, Any]
        Mapping of result types to message payloads.
    sns_topic_arn : str
        SNS topic ARN to publish all result messages.
    sns_client : botocore.client.BaseClient
        SNS client used to publish messages.
    logger : logging.Logger
        Logger used to emit structured publish logs.
    """
    for result_type, message in result.items():
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Message=json.dumps(message),
            Subject=f"Notification for {result_type}",
            MessageAttributes={
                "result_type": {
                    "DataType": "String",
                    "StringValue": result_type,
                }
            },
            MessageGroupId=load_sns_message_group_id(),
        )
        logger.info(
            "sns_publish",
            extra={"result_type": result_type, "topic_arn": sns_topic_arn},
        )
