import os
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import NullPool

from app.core.config import settings

# Vercel serverless functions cannot hold persistent TCP connections between
# invocations, so disable connection pooling when running on Vercel.
_serverless = bool(os.getenv("VERCEL"))

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    **({
        "poolclass": NullPool,
    } if _serverless else {
        "pool_pre_ping": True,
        "pool_size": 10,
        "max_overflow": 20,
    }),
)

AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


@asynccontextmanager
async def get_async_session_context() -> AsyncGenerator[AsyncSession, None]:
    """Context manager for background tasks that need their own DB session."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
