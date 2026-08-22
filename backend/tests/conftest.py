"""
Test configuration.

Each test gets a fresh SQLAlchemy engine so connections are always on the
current event loop (pytest-asyncio uses function scope per test by default).
Schema reset is done once at module load via asyncio.run() with its own engine.
"""
import asyncio
import os

os.environ["DATABASE_URL"] = (
    "postgresql+asyncpg://arise:arise_dev_password@127.0.0.1:5433/arise_test_db"
)

from collections.abc import AsyncGenerator  # noqa: E402

import pytest_asyncio  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine  # noqa: E402

from app.core.config import get_settings  # noqa: E402

get_settings.cache_clear()

import app.database.session as _db_session_module  # noqa: E402
from app.database.base import Base  # noqa: E402
from app.database.session import get_db  # noqa: E402
from app.main import app  # noqa: E402

_TEST_DB_URL = (
    "postgresql+asyncpg://arise:arise_dev_password@127.0.0.1:5433/arise_test_db"
)


# ── One-time schema reset at module load ──────────────────────────────────────

async def _reset() -> None:
    engine = create_async_engine(_TEST_DB_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    await engine.dispose()


asyncio.run(_reset())


# ── Per-test client with its own engine (always on the current loop) ──────────

@pytest_asyncio.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    # Fresh engine per test — no cross-loop contamination
    engine = create_async_engine(_TEST_DB_URL, echo=False)
    session_maker = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    # Patch the module-level session factory used by background tasks so they
    # also use the per-test engine, not a pool with stale cross-loop connections.
    _original_session_local = _db_session_module.AsyncSessionLocal
    _db_session_module.AsyncSessionLocal = session_maker

    async def _get_test_db() -> AsyncGenerator[AsyncSession, None]:
        async with session_maker() as session:
            try:
                yield session
                await session.commit()
            except Exception:
                await session.rollback()
                raise

    app.dependency_overrides[get_db] = _get_test_db
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac
    app.dependency_overrides.clear()
    _db_session_module.AsyncSessionLocal = _original_session_local
    await engine.dispose()
