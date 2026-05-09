#!/usr/bin/env bash
set -euo pipefail

uv sync
exec uv run uvicorn app:app --host 127.0.0.1 --port "$PORT"
