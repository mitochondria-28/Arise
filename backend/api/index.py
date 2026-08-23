import sys
import os

# Ensure the backend root (parent of this api/ directory) is on the path
# so that `from app.main import app` resolves correctly in Vercel's runtime.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app  # noqa: E402, F401 — re-exported for Vercel
