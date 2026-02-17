# LambdaCron Agents

- Big picture vision is kept in `IDEA.md`.
- The specific plan we're executing is in `PLAN.md`.

## General Playbook
- Keep work aligned to `PLAN.md`; propose plan updates if scope shifts.
- Use `pixi` for reproducible envs
- Add small, focused docstrings and comments only where non-obvious intent needs clarity.

## Writing Plans
- Plans should include overviews of goals and success criteria.
- Plans should include summaries of decisions made and motivations for specific choices.
- The general format of a plan is as a series of "phases," each with a clear milestone at the end, and a to-do list of steps to be taken to get there.
- Each phase should be small enough to be represented as a single PR.

## Python (boto3, pytest, moto)
- Default to Pythonic patterns: type hints, f-strings, dataclasses where helpful, and small pure functions.
- Avoid hitting real AWS: mock AWS calls with `moto` and inject sessions/clients for testability.
- Prefer dependency injection for boto3 clients; never hardcode regions or credentials.
- Tests: aim for fast, isolated `pytest` cases; use fixtures for setup/teardown; measure coverage with `pytest-cov` when meaningful.
- Run tests with `pytest` to ensure that they pass before sharing code.

## Infrastructure (opentofu)
- Keep infrastructure code formatted and validated: `tofu fmt` and `tofu validate` before sharing.
- Separate plan/apply steps; never apply without review. Capture variables in `.tfvars` or env, not inline secrets.
- AWS resources should be tagged with `managed_by`, defaulting to `lambdacron` if not set.


## Observability and Safety
- Use structured logging over prints; avoid noisy logs in hot paths.
- Fail fast with clear errors; prefer explicit exceptions to silent fallbacks.
- Keep configuration externalized (env vars/config files) and document defaults.
