import json
from io import StringIO

import pytest

from lambdacron import render


def test_render_main_renders_with_long_flags(tmp_path, capsys):
    template_path = tmp_path / "template.jinja2"
    output_path = tmp_path / "output.json"
    template_path.write_text(
        "Status {{ status }} ({{ result_type }})", encoding="utf-8"
    )
    output_path.write_text(json.dumps({"success": {"status": "ok"}}), encoding="utf-8")

    code = render.main(
        [
            "--template",
            str(template_path),
            "--result-type",
            "success",
            str(output_path),
        ]
    )

    captured = capsys.readouterr()
    assert code == 0
    assert captured.out == "Status ok (success)\n"
    assert captured.err == ""


def test_render_main_short_flags_reject_mismatched_payload_result_type(
    tmp_path, capsys
):
    template_path = tmp_path / "template.jinja2"
    output_path = tmp_path / "output.json"
    template_path.write_text("{{ result_type }}", encoding="utf-8")
    output_path.write_text(
        json.dumps({"attribute": {"status": "ok", "result_type": "payload"}}),
        encoding="utf-8",
    )

    code = render.main(["-t", str(template_path), "-r", "attribute", str(output_path)])

    captured = capsys.readouterr()
    assert code == 1
    assert (
        "Result payload for type 'attribute' has conflicting result_type 'payload'"
        in captured.err
    )


def test_render_main_rejects_non_object_json(tmp_path, capsys):
    template_path = tmp_path / "template.jinja2"
    output_path = tmp_path / "output.json"
    template_path.write_text("{{ value }}", encoding="utf-8")
    output_path.write_text(json.dumps(["not", "an", "object"]), encoding="utf-8")

    code = render.main(["-t", str(template_path), "-r", "success", str(output_path)])

    captured = capsys.readouterr()
    assert code == 1
    assert "Task output must be a JSON object keyed by result type" in captured.err


def test_render_main_uses_strict_undefined(tmp_path, capsys):
    template_path = tmp_path / "template.jinja2"
    output_path = tmp_path / "output.json"
    template_path.write_text("{{ missing }}", encoding="utf-8")
    output_path.write_text(json.dumps({"success": {"status": "ok"}}), encoding="utf-8")

    code = render.main(["-t", str(template_path), "-r", "success", str(output_path)])

    captured = capsys.readouterr()
    assert code == 1
    assert "undefined" in captured.err.lower()


def test_render_main_requires_template_and_result_type(tmp_path):
    output_path = tmp_path / "output.json"
    output_path.write_text(json.dumps({"success": {"status": "ok"}}), encoding="utf-8")

    with pytest.raises(SystemExit) as exc_info:
        render.main([str(output_path)])

    assert exc_info.value.code == 2


def test_render_main_reads_from_stdin_when_file_is_omitted(
    tmp_path, capsys, monkeypatch
):
    template_path = tmp_path / "template.jinja2"
    template_path.write_text(
        "Status {{ status }} ({{ result_type }})", encoding="utf-8"
    )
    monkeypatch.setattr(
        "sys.stdin", StringIO(json.dumps({"success": {"status": "ok"}}))
    )

    code = render.main(["-t", str(template_path), "-r", "success"])

    captured = capsys.readouterr()
    assert code == 0
    assert captured.out == "Status ok (success)\n"
    assert captured.err == ""


def test_render_main_reads_from_stdin_with_dash(tmp_path, capsys, monkeypatch):
    template_path = tmp_path / "template.jinja2"
    template_path.write_text("{{ result_type }}", encoding="utf-8")
    monkeypatch.setattr(
        "sys.stdin", StringIO(json.dumps({"success": {"status": "ok"}}))
    )

    code = render.main(["-t", str(template_path), "-r", "success", "-"])

    captured = capsys.readouterr()
    assert code == 0
    assert captured.out == "success\n"
    assert captured.err == ""


def test_render_main_preserves_matching_payload_result_type(tmp_path, capsys):
    template_path = tmp_path / "template.jinja2"
    output_path = tmp_path / "output.json"
    template_path.write_text("{{ result_type }}", encoding="utf-8")
    output_path.write_text(
        json.dumps({"success": {"status": "ok", "result_type": "success"}}),
        encoding="utf-8",
    )

    code = render.main(["-t", str(template_path), "-r", "success", str(output_path)])

    captured = capsys.readouterr()
    assert code == 0
    assert captured.out == "success\n"
    assert captured.err == ""


def test_render_main_extracts_payload_from_result_map_stdin(
    tmp_path, capsys, monkeypatch
):
    template_path = tmp_path / "template.jinja2"
    template_path.write_text(
        "Status {{ status }} ({{ result_type }})", encoding="utf-8"
    )
    monkeypatch.setattr(
        "sys.stdin",
        StringIO(
            json.dumps({"success": {"status": "ok"}, "failure": {"status": "bad"}})
        ),
    )

    code = render.main(["-t", str(template_path), "-r", "success"])

    captured = capsys.readouterr()
    assert code == 0
    assert captured.out == "Status ok (success)\n"
    assert captured.err == ""


def test_render_main_rejects_task_output_missing_result_type(tmp_path, capsys):
    template_path = tmp_path / "template.jinja2"
    output_path = tmp_path / "output.json"
    template_path.write_text("{{ status }}", encoding="utf-8")
    output_path.write_text(json.dumps({"failure": {"status": "bad"}}), encoding="utf-8")

    code = render.main(["-t", str(template_path), "-r", "success", str(output_path)])

    captured = capsys.readouterr()
    assert code == 1
    assert (
        "Result payload for type 'success' must be a JSON object, got NoneType"
        in captured.err
    )


def test_render_main_rejects_non_object_result_payload(tmp_path, capsys):
    template_path = tmp_path / "template.jinja2"
    output_path = tmp_path / "output.json"
    template_path.write_text("{{ status }}", encoding="utf-8")
    output_path.write_text(json.dumps({"success": "ok"}), encoding="utf-8")

    code = render.main(["-t", str(template_path), "-r", "success", str(output_path)])

    captured = capsys.readouterr()
    assert code == 1
    assert (
        "Result payload for type 'success' must be a JSON object, got str"
        in captured.err
    )
