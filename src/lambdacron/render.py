import argparse
import json
import sys
from pathlib import Path
from typing import Any, Mapping, TextIO

from jinja2 import TemplateError

from lambdacron.notifications.base import (
    FileTemplateProvider,
    RenderedTemplateNotificationHandler,
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Render a notification template using LambdaCron-style result payload data."
    )
    parser.add_argument(
        "output_json",
        metavar="output.json",
        nargs="?",
        default="-",
        help=(
            "JSON file containing the payload value for the selected result type. "
            "Use '-' or omit this argument to read from stdin."
        ),
    )
    parser.add_argument(
        "-t",
        "--template",
        required=True,
        type=Path,
        help="Path to the Jinja2 template file.",
    )
    parser.add_argument(
        "-r",
        "--result-type",
        required=True,
        help="Result type key to emulate from the LambdaCron task output.",
    )
    return parser


class RenderNotificationHandler(RenderedTemplateNotificationHandler):
    def __init__(self, *, template_path: Path, stream: TextIO | None = None) -> None:
        super().__init__(
            template_providers={"body": FileTemplateProvider(template_path)},
            include_result_type=True,
        )
        self.stream = stream or sys.stdout

    def notify(
        self,
        *,
        result: Mapping[str, Any],
        rendered: Mapping[str, str],
        record: Mapping[str, Any],
    ) -> None:
        print(rendered["body"], file=self.stream)

    def render_payload(self, *, payload_json: str, result_type: str) -> None:
        event = {
            "Records": [
                {
                    "body": payload_json,
                    "eventSource": "aws:sqs",
                    "messageAttributes": {
                        "result_type": {
                            "DataType": "String",
                            "StringValue": result_type,
                        }
                    },
                }
            ]
        }
        self.lambda_handler(event=event, context=None)


def read_payload_json(source: str, *, stdin: TextIO) -> str:
    if source == "-":
        payload_json = stdin.read()
        if not payload_json.strip():
            raise ValueError("stdin did not contain JSON content")
        return payload_json
    return Path(source).read_text(encoding="utf-8")


def maybe_extract_result_payload(payload_json: str, *, result_type: str) -> str:
    try:
        payload = json.loads(payload_json)
    except json.JSONDecodeError:
        return payload_json
    if not isinstance(payload, dict):
        return payload_json
    selected = payload.get(result_type)
    if "result_type" not in payload and isinstance(selected, dict):
        return json.dumps(selected)
    return payload_json


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        payload_json = read_payload_json(args.output_json, stdin=sys.stdin)
        payload_json = maybe_extract_result_payload(
            payload_json, result_type=args.result_type
        )
        handler = RenderNotificationHandler(template_path=args.template)
        handler.render_payload(payload_json=payload_json, result_type=args.result_type)
    except (OSError, ValueError, TemplateError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
