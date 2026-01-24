import json
import logging
import os
from abc import ABC, abstractmethod
from typing import Any, Mapping, Optional

from jinja2 import Environment, StrictUndefined


class TemplateProvider(ABC):
    """
    Base class for retrieving notification templates.
    """

    @abstractmethod
    def get_template(self) -> str:
        """
        Return a Jinja2 template string.

        Returns
        -------
        str
            Template contents as a string.
        """
        raise NotImplementedError


class EnvVarTemplateProvider(TemplateProvider):
    """
    Load a notification template from an environment variable.

    Parameters
    ----------
    env_var : str, optional
        Environment variable containing the template string.
    """

    def __init__(self, env_var: str = "TEMPLATE") -> None:
        self.env_var = env_var

    def get_template(self) -> str:
        """
        Return a Jinja2 template string from the configured environment variable.

        Returns
        -------
        str
            Template contents as a string.

        Raises
        ------
        ValueError
            If the environment variable is missing or empty.
        """
        template = os.environ.get(self.env_var)
        if not template:
            raise ValueError(f"{self.env_var} must be set to a non-empty template")
        return template


class RenderedTemplateNotificationHandler(ABC):
    """
    Base class for SQS-driven notifications using Jinja2 templates.

    Parameters
    ----------
    template_providers : Mapping[str, TemplateProvider]
        Providers keyed by template name for rendering.
    expected_queue_arn : str, optional
        Queue ARN to validate incoming SQS records.
    include_result_type : bool, optional
        Whether to include the SNS message attribute ``result_type`` in the payload.
    logger : logging.Logger, optional
        Logger used for structured logging.
    jinja_env : jinja2.Environment, optional
        Jinja2 environment used for rendering templates.
    """

    def __init__(
        self,
        template_providers: Mapping[str, TemplateProvider],
        *,
        expected_queue_arn: Optional[str] = None,
        include_result_type: bool = True,
        logger: Optional[logging.Logger] = None,
        jinja_env: Optional[Environment] = None,
    ) -> None:
        self.template_providers = dict(template_providers)
        self.expected_queue_arn = expected_queue_arn
        self.include_result_type = include_result_type
        self.logger = logger or logging.getLogger(self.__class__.__name__)
        self.jinja_env = jinja_env or Environment(undefined=StrictUndefined)

    def lambda_handler(
        self, event: Mapping[str, Any], context: Any
    ) -> dict[str, list[dict[str, str]]]:
        """
        Entry point for SQS-triggered notification handlers.

        Parameters
        ----------
        event : Mapping[str, Any]
            Lambda event payload containing SQS records.
        context : Any
            Lambda context object.

        Returns
        -------
        dict[str, list[dict[str, str]]]
            Batch item failures payload for SQS partial retries.
        """
        self.logger.info(
            "notification_invocation",
            extra={"record_count": len(event.get("Records", []))},
        )
        templates = {
            name: provider.get_template()
            for name, provider in self.template_providers.items()
        }
        failures = []
        records = event.get("Records", [])
        for record in records:
            try:
                self._validate_record(record)
                result = self._parse_result(record)
                rendered = self._render_templates(templates, result)
                self.notify(result=result, rendered=rendered, record=record)
            except Exception as exc:
                message_id = record.get("messageId")
                if not message_id:
                    raise
                self.logger.exception(
                    "notification_record_failed",
                    extra={"message_id": message_id, "error": str(exc)},
                )
                failures.append({"itemIdentifier": message_id})
        return {"batchItemFailures": failures}

    @abstractmethod
    def notify(
        self,
        *,
        result: Mapping[str, Any],
        rendered: Mapping[str, str],
        record: Mapping[str, Any],
    ) -> None:
        """
        Send the rendered notification payload to the target channel.

        Parameters
        ----------
        result : Mapping[str, Any]
            Parsed result payload from the SNS-to-SQS pipeline.
        rendered : Mapping[str, str]
            Rendered template output keyed by template name.
        record : Mapping[str, Any]
            Original SQS record for additional metadata.
        """
        raise NotImplementedError

    def _validate_record(self, record: Mapping[str, Any]) -> None:
        event_source = record.get("eventSource")
        if event_source and event_source != "aws:sqs":
            raise ValueError(f"Unsupported event source: {event_source}")
        if self.expected_queue_arn:
            event_arn = record.get("eventSourceARN")
            if event_arn != self.expected_queue_arn:
                raise ValueError(
                    f"SQS queue mismatch (expected {self.expected_queue_arn}, got {event_arn})"
                )

    def _parse_result(self, record: Mapping[str, Any]) -> Mapping[str, Any]:
        body = record.get("body")
        if not body:
            raise ValueError("SQS record body is missing")
        try:
            payload = json.loads(body)
        except json.JSONDecodeError as exc:
            raise ValueError("SQS record body must be valid JSON") from exc
        if isinstance(payload, dict) and "Message" in payload:
            message = payload.get("Message")
            if not isinstance(message, str):
                raise ValueError("SNS message must be a JSON string")
            try:
                payload = json.loads(message)
            except json.JSONDecodeError as exc:
                raise ValueError("SNS message must be valid JSON") from exc
        if not isinstance(payload, dict):
            raise ValueError("Result payload must be a JSON object")
        if self.include_result_type:
            result_type = self._extract_result_type(record)
            if result_type and "result_type" not in payload:
                payload["result_type"] = result_type
        return payload

    def _render_template(self, template: str, result: Mapping[str, Any]) -> str:
        jinja_template = self.jinja_env.from_string(template)
        return jinja_template.render(**result)

    def _render_templates(
        self, templates: Mapping[str, str], result: Mapping[str, Any]
    ) -> dict[str, str]:
        return {
            name: self._render_template(template, result)
            for name, template in templates.items()
        }

    @staticmethod
    def _extract_result_type(record: Mapping[str, Any]) -> Optional[str]:
        attributes = record.get("messageAttributes", {})
        result_attr = attributes.get("result_type", {})
        value = result_attr.get("stringValue") or result_attr.get("StringValue")
        if isinstance(value, str) and value:
            return value
        return None
