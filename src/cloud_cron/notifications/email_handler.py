import logging
from typing import Any, Mapping, Optional, Sequence

import boto3
from botocore.exceptions import ClientError
from jinja2 import Environment

from cloud_cron.notifications.base import (
    RenderedTemplateNotificationHandler,
    TemplateProvider,
)


class EmailNotificationHandler(RenderedTemplateNotificationHandler):
    """
    Notification handler that renders subject/text/html templates and sends via SES.

    Parameters
    ----------
    subject_template_provider : TemplateProvider
        Provider that returns the subject template string for rendering.
    text_template_provider : TemplateProvider
        Provider that returns the plaintext body template string for rendering.
    html_template_provider : TemplateProvider
        Provider that returns the HTML body template string for rendering.
    sender : str
        SES verified sender address.
    recipients : Sequence[str]
        Default recipient list.
    ses_client : Any, optional
        Injected SES client for testing or customization.
    config_set : str, optional
        Optional SES configuration set name.
    reply_to : Sequence[str], optional
        Optional reply-to addresses.
    expected_queue_arn : str, optional
        Queue ARN to validate incoming SQS records.
    logger : logging.Logger, optional
        Logger used for structured logging.
    jinja_env : jinja2.Environment, optional
        Jinja2 environment used for rendering templates.
    """

    def __init__(
        self,
        *,
        subject_template_provider: TemplateProvider,
        text_template_provider: TemplateProvider,
        html_template_provider: TemplateProvider,
        sender: str,
        recipients: Sequence[str],
        ses_client: Optional[Any] = None,
        config_set: Optional[str] = None,
        reply_to: Optional[Sequence[str]] = None,
        expected_queue_arn: Optional[str] = None,
        logger: Optional[logging.Logger] = None,
        jinja_env: Optional[Environment] = None,
    ) -> None:
        super().__init__(
            template_providers={
                "subject": subject_template_provider,
                "text": text_template_provider,
                "html": html_template_provider,
            },
            expected_queue_arn=expected_queue_arn,
            logger=logger,
            jinja_env=jinja_env,
        )
        self.sender = sender
        if not recipients:
            raise ValueError("recipients must contain at least one email address")
        self.recipients = list(recipients)
        self.config_set = config_set
        self.reply_to = list(reply_to) if reply_to else None
        self.ses_client = ses_client or boto3.client("ses")

    def notify(
        self,
        *,
        result: Mapping[str, Any],
        rendered: Mapping[str, str],
        record: Mapping[str, Any],
    ) -> None:
        """
        Send the rendered email payload via SES.

        Parameters
        ----------
        result : Mapping[str, Any]
            Parsed result payload from the SNS-to-SQS pipeline.
        rendered : Mapping[str, str]
            Rendered subject/text/html strings.
        record : Mapping[str, Any]
            Original SQS record for additional metadata.
        """
        message = {
            "Subject": {"Data": rendered["subject"], "Charset": "UTF-8"},
            "Body": {
                "Text": {"Data": rendered["text"], "Charset": "UTF-8"},
                "Html": {"Data": rendered["html"], "Charset": "UTF-8"},
            },
        }
        payload = {
            "Source": self.sender,
            "Destination": {"ToAddresses": self.recipients},
            "Message": message,
        }
        if self.config_set:
            payload["ConfigurationSetName"] = self.config_set
        if self.reply_to:
            payload["ReplyToAddresses"] = self.reply_to
        try:
            response = self.ses_client.send_email(**payload)
        except ClientError as exc:
            error = exc.response.get("Error", {})
            meta = exc.response.get("ResponseMetadata", {})
            self.logger.exception(
                "ses_email_failed",
                extra={
                    "error_code": error.get("Code"),
                    "error_message": error.get("Message"),
                    "request_id": meta.get("RequestId"),
                    "http_status": meta.get("HTTPStatusCode"),
                },
            )
            raise
        self.logger.info(
            "ses_email_sent",
            extra={"message_id": response.get("MessageId")},
        )
