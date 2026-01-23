import json
import os

from cloud_cron.notifications.base import EnvVarTemplateProvider
from cloud_cron.notifications.email_handler import EmailNotificationHandler


def _load_json_list(env_var, *, required=False):
    raw = os.environ.get(env_var)
    if not raw:
        if required:
            raise ValueError(f"{env_var} must be set to a JSON list")
        return []
    return json.loads(raw)


handler_instance = EmailNotificationHandler(
    subject_template_provider=EnvVarTemplateProvider("EMAIL_SUBJECT_TEMPLATE"),
    text_template_provider=EnvVarTemplateProvider("EMAIL_TEXT_TEMPLATE"),
    html_template_provider=EnvVarTemplateProvider("EMAIL_HTML_TEMPLATE"),
    sender=os.environ["EMAIL_SENDER"],
    recipients=_load_json_list("EMAIL_RECIPIENTS", required=True),
    reply_to=_load_json_list("EMAIL_REPLY_TO"),
)


def handler(event, context):
    handler_instance.lambda_handler(event, context)
