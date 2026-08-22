#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
#  Arise — Initial project setup
#  Run once after cloning: bash scripts/setup.sh
# ─────────────────────────────────────────────────────────
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}▶ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }

log "Setting up Arise..."

# 1. Root .env
if [ ! -f .env ]; then
  cp .env.example .env
  log ".env created from .env.example"
  warn "Edit .env and fill in your GEMINI_API_KEY and JWT_SECRET_KEY before running."
else
  log ".env already exists — skipping"
fi

# 2. Backend
log "Installing backend dependencies..."
cd backend
if command -v uv &>/dev/null; then
  uv pip install -e ".[dev]"
else
  python3 -m pip install -e ".[dev]"
fi
cd ..
log "Backend dependencies installed"

# 3. Web
log "Installing web dependencies..."
cd web
npm install
cd ..
log "Web dependencies installed"

# 4. Flutter
log "Getting Flutter packages..."
cd mobile
flutter pub get
cd ..
log "Flutter packages installed"

echo ""
log "Setup complete!"
echo ""
echo "  Next steps:"
echo "  1. Edit .env — add GEMINI_API_KEY and generate JWT_SECRET_KEY"
echo "  2. Start PostgreSQL (Docker: docker compose up postgres -d)"
echo "  3. Run migrations: bash scripts/migrate.sh"
echo "  4. Start backend: bash scripts/dev-backend.sh"
echo "  5. Start web: bash scripts/dev-web.sh"
