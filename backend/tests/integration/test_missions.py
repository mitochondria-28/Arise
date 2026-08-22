import os
import uuid
from datetime import datetime, timedelta, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.models.mission import Mission

_DB = os.environ["DATABASE_URL"]

_MISSION_PAYLOAD = {
    "title": "Morning run",
    "description": "30 minutes, any pace.",
    "category": "vitality",
    "difficulty": "medium",
    "frequency": "daily",
}


async def _register(client: AsyncClient, email: str) -> dict:
    r = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "TestPass123!"},
    )
    assert r.status_code == 201
    return r.json()


def _auth(tokens: dict) -> dict:
    return {"Authorization": f"Bearer {tokens['access_token']}"}


_CHECKIN = {
    "evidence_text": "Ran 3.2 km in 32 minutes, tracked via Strava.",
    "effort_level": 3,
}


async def _set_last_completed_days_ago(mission_id: str, days: int) -> None:
    """Backdate last_completed_at to simulate past check-ins (for streak tests)."""
    engine = create_async_engine(_DB, echo=False)
    maker = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with maker() as session:
        result = await session.execute(select(Mission).where(Mission.id == uuid.UUID(mission_id)))
        m = result.scalar_one()
        m.last_completed_at = datetime.now(timezone.utc) - timedelta(days=days)
        await session.commit()
    await engine.dispose()


# ── Create ─────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_create_mission_success(client: AsyncClient):
    tokens = await _register(client, "miss_create@example.com")
    r = await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens))
    assert r.status_code == 201
    data = r.json()
    assert data["title"] == "Morning run"
    assert data["frequency"] == "daily"
    assert data["status"] == "active"
    assert data["current_streak"] == 0
    assert data["can_checkin_now"] is True


@pytest.mark.asyncio
async def test_create_mission_invalid_frequency(client: AsyncClient):
    tokens = await _register(client, "miss_badfreq@example.com")
    r = await client.post(
        "/api/v1/missions",
        json={**_MISSION_PAYLOAD, "frequency": "hourly"},
        headers=_auth(tokens),
    )
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_create_mission_unauthenticated(client: AsyncClient):
    r = await client.post("/api/v1/missions", json=_MISSION_PAYLOAD)
    assert r.status_code == 401


# ── List ───────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_list_missions_empty(client: AsyncClient):
    tokens = await _register(client, "miss_listempty@example.com")
    r = await client.get("/api/v1/missions", headers=_auth(tokens))
    assert r.status_code == 200
    assert r.json()["total"] == 0


@pytest.mark.asyncio
async def test_list_missions_after_create(client: AsyncClient):
    tokens = await _register(client, "miss_listafter@example.com")
    await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens))
    await client.post(
        "/api/v1/missions",
        json={**_MISSION_PAYLOAD, "title": "Evening meditation", "category": "wisdom", "frequency": "weekly"},
        headers=_auth(tokens),
    )
    r = await client.get("/api/v1/missions", headers=_auth(tokens))
    assert r.json()["total"] == 2


@pytest.mark.asyncio
async def test_list_missions_filter_by_frequency(client: AsyncClient):
    tokens = await _register(client, "miss_filterfreq@example.com")
    await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens))
    await client.post(
        "/api/v1/missions",
        json={**_MISSION_PAYLOAD, "title": "Weekly review", "frequency": "weekly"},
        headers=_auth(tokens),
    )
    r = await client.get("/api/v1/missions?frequency=daily", headers=_auth(tokens))
    assert r.json()["total"] == 1
    r = await client.get("/api/v1/missions?frequency=weekly", headers=_auth(tokens))
    assert r.json()["total"] == 1


# ── Get ────────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_get_mission_by_id(client: AsyncClient):
    tokens = await _register(client, "miss_getid@example.com")
    created = (
        await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens))
    ).json()
    r = await client.get(f"/api/v1/missions/{created['id']}", headers=_auth(tokens))
    assert r.status_code == 200
    assert r.json()["id"] == created["id"]


@pytest.mark.asyncio
async def test_get_other_users_mission_is_404(client: AsyncClient):
    tokens_a = await _register(client, "miss_owner@example.com")
    tokens_b = await _register(client, "miss_intruder@example.com")
    mission = (
        await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens_a))
    ).json()
    r = await client.get(f"/api/v1/missions/{mission['id']}", headers=_auth(tokens_b))
    assert r.status_code == 404


# ── Check-in ──────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_checkin_success(client: AsyncClient):
    tokens = await _register(client, "miss_checkin@example.com")
    mission = (
        await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens))
    ).json()

    r = await client.post(
        f"/api/v1/missions/{mission['id']}/checkin",
        json=_CHECKIN,
        headers=_auth(tokens),
    )
    assert r.status_code == 200
    data = r.json()
    assert data["new_streak"] == 1
    assert data["xp_awarded"] == 100  # medium + effort 3, streak 1 = 1.0x
    assert data["mission"]["current_streak"] == 1
    assert data["mission"]["completion_count"] == 1
    assert data["mission"]["can_checkin_now"] is False


@pytest.mark.asyncio
async def test_checkin_awards_xp_to_character(client: AsyncClient):
    tokens = await _register(client, "miss_xp@example.com")
    mission = (
        await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens))
    ).json()

    await client.post(
        f"/api/v1/missions/{mission['id']}/checkin",
        json=_CHECKIN,
        headers=_auth(tokens),
    )

    char = (await client.get("/api/v1/character", headers=_auth(tokens))).json()
    assert char["total_xp"] == 100
    assert char["stats"]["vitality"] == 1


@pytest.mark.asyncio
async def test_double_checkin_same_day_blocked(client: AsyncClient):
    tokens = await _register(client, "miss_double@example.com")
    mission = (
        await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens))
    ).json()

    await client.post(
        f"/api/v1/missions/{mission['id']}/checkin", json=_CHECKIN, headers=_auth(tokens)
    )
    r = await client.post(
        f"/api/v1/missions/{mission['id']}/checkin", json=_CHECKIN, headers=_auth(tokens)
    )
    assert r.status_code == 409


@pytest.mark.asyncio
async def test_checkin_evidence_too_short(client: AsyncClient):
    tokens = await _register(client, "miss_shortev@example.com")
    mission = (
        await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens))
    ).json()
    r = await client.post(
        f"/api/v1/missions/{mission['id']}/checkin",
        json={"evidence_text": "Done", "effort_level": 3},
        headers=_auth(tokens),
    )
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_checkin_continues_streak(client: AsyncClient):
    tokens = await _register(client, "miss_streak@example.com")
    mission = (
        await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens))
    ).json()

    # First check-in → streak = 1
    await client.post(
        f"/api/v1/missions/{mission['id']}/checkin", json=_CHECKIN, headers=_auth(tokens)
    )
    # Backdate to yesterday so next check-in is consecutive
    await _set_last_completed_days_ago(mission["id"], 1)

    r = await client.post(
        f"/api/v1/missions/{mission['id']}/checkin", json=_CHECKIN, headers=_auth(tokens)
    )
    assert r.status_code == 200
    data = r.json()
    assert data["new_streak"] == 2
    assert data["mission"]["longest_streak"] == 2


@pytest.mark.asyncio
async def test_checkin_breaks_streak(client: AsyncClient):
    tokens = await _register(client, "miss_breakstreak@example.com")
    mission = (
        await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens))
    ).json()

    await client.post(
        f"/api/v1/missions/{mission['id']}/checkin", json=_CHECKIN, headers=_auth(tokens)
    )
    # Backdate to 3 days ago (missed yesterday → streak breaks)
    await _set_last_completed_days_ago(mission["id"], 3)

    r = await client.post(
        f"/api/v1/missions/{mission['id']}/checkin", json=_CHECKIN, headers=_auth(tokens)
    )
    data = r.json()
    assert data["new_streak"] == 1  # reset


@pytest.mark.asyncio
async def test_streak_7_gives_bonus_xp(client: AsyncClient):
    tokens = await _register(client, "miss_streak7@example.com")
    mission = (
        await client.post(
            "/api/v1/missions",
            json={**_MISSION_PAYLOAD, "difficulty": "medium"},
            headers=_auth(tokens),
        )
    ).json()

    # Simulate 6 prior check-ins so next is streak=7
    engine = create_async_engine(_DB, echo=False)
    maker = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with maker() as session:
        result = await session.execute(
            select(Mission).where(Mission.id == uuid.UUID(mission["id"]))
        )
        m = result.scalar_one()
        m.current_streak = 6
        m.longest_streak = 6
        m.completion_count = 6
        m.last_completed_at = datetime.now(timezone.utc) - timedelta(days=1)
        await session.commit()
    await engine.dispose()

    r = await client.post(
        f"/api/v1/missions/{mission['id']}/checkin", json=_CHECKIN, headers=_auth(tokens)
    )
    data = r.json()
    assert data["new_streak"] == 7
    # medium + effort 3 = 100 base, streak 7 = 1.25x → 125
    assert data["xp_awarded"] == 125


# ── Auto-complete on target_count ─────────────────────────────────────────────

@pytest.mark.asyncio
async def test_mission_auto_completes_on_target(client: AsyncClient):
    tokens = await _register(client, "miss_autocomplete@example.com")
    mission = (
        await client.post(
            "/api/v1/missions",
            json={**_MISSION_PAYLOAD, "target_count": 1},
            headers=_auth(tokens),
        )
    ).json()

    r = await client.post(
        f"/api/v1/missions/{mission['id']}/checkin", json=_CHECKIN, headers=_auth(tokens)
    )
    assert r.json()["mission"]["status"] == "completed"

    # Can't check in again
    r2 = await client.post(
        f"/api/v1/missions/{mission['id']}/checkin", json=_CHECKIN, headers=_auth(tokens)
    )
    assert r2.status_code == 409


# ── Logs ───────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_mission_logs_after_checkin(client: AsyncClient):
    tokens = await _register(client, "miss_logs@example.com")
    mission = (
        await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens))
    ).json()

    await client.post(
        f"/api/v1/missions/{mission['id']}/checkin", json=_CHECKIN, headers=_auth(tokens)
    )

    r = await client.get(
        f"/api/v1/missions/{mission['id']}/logs", headers=_auth(tokens)
    )
    assert r.status_code == 200
    data = r.json()
    assert data["total"] == 1
    assert data["logs"][0]["streak_at_checkin"] == 1
    assert data["logs"][0]["xp_awarded"] == 100


# ── Update ─────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_update_mission_title(client: AsyncClient):
    tokens = await _register(client, "miss_update@example.com")
    mission = (
        await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens))
    ).json()
    r = await client.patch(
        f"/api/v1/missions/{mission['id']}",
        json={"title": "Evening run"},
        headers=_auth(tokens),
    )
    assert r.status_code == 200
    assert r.json()["title"] == "Evening run"


@pytest.mark.asyncio
async def test_pause_and_resume_mission(client: AsyncClient):
    tokens = await _register(client, "miss_pause@example.com")
    mission = (
        await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens))
    ).json()

    r = await client.patch(
        f"/api/v1/missions/{mission['id']}",
        json={"status": "paused"},
        headers=_auth(tokens),
    )
    assert r.json()["status"] == "paused"
    assert r.json()["can_checkin_now"] is False

    r = await client.patch(
        f"/api/v1/missions/{mission['id']}",
        json={"status": "active"},
        headers=_auth(tokens),
    )
    assert r.json()["status"] == "active"


# ── Archive ────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_archive_mission(client: AsyncClient):
    tokens = await _register(client, "miss_archive@example.com")
    mission = (
        await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens))
    ).json()

    r = await client.delete(f"/api/v1/missions/{mission['id']}", headers=_auth(tokens))
    assert r.status_code == 204

    r = await client.get(f"/api/v1/missions/{mission['id']}", headers=_auth(tokens))
    assert r.json()["status"] == "archived"


# ── Isolation ──────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_missions_isolated_between_users(client: AsyncClient):
    tokens_a = await _register(client, "miss_iso_a@example.com")
    tokens_b = await _register(client, "miss_iso_b@example.com")
    await client.post("/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens_a))
    r = await client.get("/api/v1/missions", headers=_auth(tokens_b))
    assert r.json()["total"] == 0
