#!/usr/bin/env bash
# Start the FastAPI backend in development mode
set -euo pipefail

cd "$(dirname "$0")/../backend"
# pydantic-settings reads .env directly — no bash source needed
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
