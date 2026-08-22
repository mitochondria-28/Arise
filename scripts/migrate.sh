#!/usr/bin/env bash
# Run Alembic migrations
set -euo pipefail

cd "$(dirname "$0")/../backend"
# pydantic-settings reads .env directly — no bash source needed
alembic upgrade head
echo "Migrations applied."
