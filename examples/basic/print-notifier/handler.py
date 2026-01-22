from cloud_cron.notifications.base import EnvVarTemplateProvider
from cloud_cron.notifications.print_handler import PrintNotificationHandler

handler_instance = PrintNotificationHandler(
    template_provider=EnvVarTemplateProvider(),
)


def handler(event, context):
    handler_instance.lambda_handler(event, context)
