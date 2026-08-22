#!/usr/bin/env bash
# Start the React web app in development mode
set -euo pipefail

cd "$(dirname "$0")/../web"
npm run dev
