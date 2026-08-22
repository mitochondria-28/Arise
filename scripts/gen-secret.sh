#!/usr/bin/env bash
# Generate a secure JWT_SECRET_KEY
python3 -c "import secrets; print(secrets.token_hex(64))"
