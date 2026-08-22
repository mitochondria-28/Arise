import os
import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.services.character_service import CharacterService

_DB = os.environ["DATABASE_URL"]


async def _register(client: AsyncClient, email: str) -> dict:
    r = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "TestPass123!"},
    )
    assert r.status_code == 201
    return r.json()


async def _award_xp(
    char_id: str,
    amount: int,
    source_type: str = "test",
    **kwargs,
) -> tuple:
    """Award XP via service layer, in its own committed session."""
    engine = create_async_engine(_DB, echo=False)
    maker = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with maker() as session:
        service = CharacterService(session)
        result = await service.award_xp(
            uuid.UUID(char_id), amount, source_type, **kwargs
        )
        await session.commit()
    await engine.dispose()
    return result


# ── Character created on register ─────────────────────────────────────────────

@pytest.mark.asyncio
async def test_character_created_on_register(client: AsyncClient):
    tokens = await _register(client, "char_created@example.com")
    r = await client.get(
        "/api/v1/character",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    assert r.status_code == 200


@pytest.mark.asyncio
async def test_character_default_state(client: AsyncClient):
    tokens = await _register(client, "char_defaults@example.com")
    r = await client.get(
        "/api/v1/character",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    data = r.json()
    assert data["level"] == 1
    assert data["rank"] == "E"
    assert data["total_xp"] == 0
    assert data["current_level_xp"] == 0
    assert data["xp_to_next_level"] == 100
    assert data["title"] == "The Awakened"


@pytest.mark.asyncio
async def test_character_stats_all_zero(client: AsyncClient):
    tokens = await _register(client, "char_stats@example.com")
    r = await client.get(
        "/api/v1/character",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    stats = r.json()["stats"]
    assert stats is not None
    for stat in ("vitality", "strength", "intelligence", "wisdom", "charisma", "discipline"):
        assert stats[stat] == 0, f"{stat} should start at 0"


# ── XP history ────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_xp_history_empty_on_new_character(client: AsyncClient):
    tokens = await _register(client, "xp_history_empty@example.com")
    r = await client.get(
        "/api/v1/character/xp/history",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    assert r.status_code == 200
    data = r.json()
    assert data["transactions"] == []
    assert data["total"] == 0
    assert data["page"] == 1


# ── Auth enforcement ──────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_get_character_unauthenticated(client: AsyncClient):
    r = await client.get("/api/v1/character")
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_xp_history_unauthenticated(client: AsyncClient):
    r = await client.get("/api/v1/character/xp/history")
    assert r.status_code == 401


# ── XP award via service layer ────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_award_xp_updates_total_and_stat(client: AsyncClient):
    tokens = await _register(client, "xp_award@example.com")
    char_data = (
        await client.get(
            "/api/v1/character",
            headers={"Authorization": f"Bearer {tokens['access_token']}"},
        )
    ).json()

    await _award_xp(
        char_data["id"],
        50,
        stat_category="intelligence",
        description="Test award",
    )

    r = await client.get(
        "/api/v1/character",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    data = r.json()
    assert data["total_xp"] == 50
    assert data["current_level_xp"] == 50
    assert data["stats"]["intelligence"] == 1


@pytest.mark.asyncio
async def test_award_xp_triggers_levelup(client: AsyncClient):
    tokens = await _register(client, "levelup@example.com")
    char_data = (
        await client.get(
            "/api/v1/character",
            headers={"Authorization": f"Bearer {tokens['access_token']}"},
        )
    ).json()

    _, levels_gained = await _award_xp(
        char_data["id"], 100, description="Level-up award"
    )
    assert levels_gained == [2]

    r = await client.get(
        "/api/v1/character",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    data = r.json()
    assert data["level"] == 2
    assert data["current_level_xp"] == 0
    assert data["total_xp"] == 100


@pytest.mark.asyncio
async def test_xp_history_records_transaction(client: AsyncClient):
    tokens = await _register(client, "xp_history_txn@example.com")
    char_data = (
        await client.get(
            "/api/v1/character",
            headers={"Authorization": f"Bearer {tokens['access_token']}"},
        )
    ).json()

    await _award_xp(char_data["id"], 75, description="History record test")

    r = await client.get(
        "/api/v1/character/xp/history",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    data = r.json()
    assert data["total"] == 1
    assert data["transactions"][0]["amount"] == 75
    assert data["transactions"][0]["source_type"] == "test"


@pytest.mark.asyncio
async def test_xp_history_pagination(client: AsyncClient):
    tokens = await _register(client, "xp_pagination@example.com")
    char_data = (
        await client.get(
            "/api/v1/character",
            headers={"Authorization": f"Bearer {tokens['access_token']}"},
        )
    ).json()
    char_id = char_data["id"]

    for i in range(5):
        await _award_xp(char_id, 10, description=f"Award {i}")

    r = await client.get(
        "/api/v1/character/xp/history?page=1&page_size=3",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    data = r.json()
    assert data["total"] == 5
    assert len(data["transactions"]) == 3
    assert data["page"] == 1
    assert data["page_size"] == 3
