import json
import os
from typing import Any

from lambdacron.notifications.base import EnvVarTemplateProvider
from lambdacron.notifications.email_handler import EmailNotificationHandler
from lambdacron.notifications.print_handler import PrintNotificationHandler


def _load_json_list(env_var: str, *, required: bool = False) -> list[str]:
    raw = os.environ.get(env_var)
    if not raw:
        if required:
            raise ValueError(f"{env_var} must be set to a JSON list")
        return []
    return json.loads(raw)


def email_handler(
    event: dict[str, Any], context: Any
) -> dict[str, list[dict[str, str]]]:
    handler_instance = EmailNotificationHandler(
        subject_template_provider=EnvVarTemplateProvider("EMAIL_SUBJECT_TEMPLATE"),
        text_template_provider=EnvVarTemplateProvider("EMAIL_TEXT_TEMPLATE"),
        html_template_provider=EnvVarTemplateProvider("EMAIL_HTML_TEMPLATE"),
        sender=os.environ["EMAIL_SENDER"],
        recipients=_load_json_list("EMAIL_RECIPIENTS", required=True),
        reply_to=_load_json_list("EMAIL_REPLY_TO"),
    )
    return handler_instance.lambda_handler(event, context)


def print_handler(
    event: dict[str, Any], context: Any
) -> dict[str, list[dict[str, str]]]:
    handler_instance = PrintNotificationHandler(
        template_provider=EnvVarTemplateProvider(),
    )
    return handler_instance.lambda_handler(event, context)
