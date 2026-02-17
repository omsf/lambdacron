from typing import Any, Mapping

from lambdacron.notifications.base import (
    RenderedTemplateNotificationHandler,
    TemplateProvider,
)


class PrintNotificationHandler(RenderedTemplateNotificationHandler):
    """
    Notification handler that logs rendered templates for testing.

    Parameters
    ----------
    template_provider : TemplateProvider
        Provider that returns the template string for rendering.
    expected_queue_arn : str, optional
        Queue ARN to validate incoming SQS records.
    logger : logging.Logger, optional
        Logger used for structured logging.
    """

    def __init__(
        self,
        *,
        template_provider: TemplateProvider,
        expected_queue_arn: str | None = None,
        include_result_type: bool = True,
        logger: Any | None = None,
    ) -> None:
        super().__init__(
            template_providers={"body": template_provider},
            expected_queue_arn=expected_queue_arn,
            include_result_type=include_result_type,
            logger=logger,
        )

    def notify(
        self,
        *,
        result: Mapping[str, Any],
        rendered: Mapping[str, str],
        record: Mapping[str, Any],
    ) -> None:
        """
        Log the rendered notification payload.

        Parameters
        ----------
        result : Mapping[str, Any]
            Parsed result payload from the SNS-to-SQS pipeline.
        rendered : Mapping[str, str]
            Rendered template output keyed by template name.
        record : Mapping[str, Any]
            Original SQS record for additional metadata.
        """
        print(rendered["body"])
