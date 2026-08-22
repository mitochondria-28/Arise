import pytest
from httpx import AsyncClient


async def _register(client: AsyncClient, email: str) -> dict:
    r = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "TestPass123!"},
    )
    assert r.status_code == 201
    return r.json()


def _auth(tokens: dict) -> dict:
    return {"Authorization": f"Bearer {tokens['access_token']}"}


_GOAL_PAYLOAD = {
    "title": "Read 12 books this year",
    "description": "One per month, any genre.",
    "category": "intelligence",
    "difficulty": "medium",
}


# ── Create ─────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_create_goal_success(client: AsyncClient):
    tokens = await _register(client, "goal_create@example.com")
    r = await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens))
    assert r.status_code == 201
    data = r.json()
    assert data["title"] == "Read 12 books this year"
    assert data["category"] == "intelligence"
    assert data["difficulty"] == "medium"
    assert data["status"] == "active"
    assert data["completion"] is None


@pytest.mark.asyncio
async def test_create_goal_invalid_category(client: AsyncClient):
    tokens = await _register(client, "goal_badcat@example.com")
    r = await client.post(
        "/api/v1/goals",
        json={**_GOAL_PAYLOAD, "category": "magic"},
        headers=_auth(tokens),
    )
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_create_goal_invalid_difficulty(client: AsyncClient):
    tokens = await _register(client, "goal_baddiff@example.com")
    r = await client.post(
        "/api/v1/goals",
        json={**_GOAL_PAYLOAD, "difficulty": "legendary"},
        headers=_auth(tokens),
    )
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_create_goal_title_too_short(client: AsyncClient):
    tokens = await _register(client, "goal_shorttitle@example.com")
    r = await client.post(
        "/api/v1/goals",
        json={**_GOAL_PAYLOAD, "title": ""},
        headers=_auth(tokens),
    )
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_create_goal_unauthenticated(client: AsyncClient):
    r = await client.post("/api/v1/goals", json=_GOAL_PAYLOAD)
    assert r.status_code == 401


# ── List ───────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_list_goals_empty(client: AsyncClient):
    tokens = await _register(client, "goal_listempty@example.com")
    r = await client.get("/api/v1/goals", headers=_auth(tokens))
    assert r.status_code == 200
    data = r.json()
    assert data["goals"] == []
    assert data["total"] == 0


@pytest.mark.asyncio
async def test_list_goals_after_create(client: AsyncClient):
    tokens = await _register(client, "goal_listafter@example.com")
    await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens))
    await client.post(
        "/api/v1/goals",
        json={**_GOAL_PAYLOAD, "title": "Run a 5K", "category": "vitality"},
        headers=_auth(tokens),
    )
    r = await client.get("/api/v1/goals", headers=_auth(tokens))
    data = r.json()
    assert data["total"] == 2
    assert len(data["goals"]) == 2


@pytest.mark.asyncio
async def test_list_goals_filter_by_status(client: AsyncClient):
    tokens = await _register(client, "goal_filterstatus@example.com")
    await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens))

    r = await client.get("/api/v1/goals?status=active", headers=_auth(tokens))
    assert r.json()["total"] == 1

    r = await client.get("/api/v1/goals?status=completed", headers=_auth(tokens))
    assert r.json()["total"] == 0


@pytest.mark.asyncio
async def test_list_goals_filter_by_category(client: AsyncClient):
    tokens = await _register(client, "goal_filtercat@example.com")
    await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens))
    await client.post(
        "/api/v1/goals",
        json={**_GOAL_PAYLOAD, "title": "Run", "category": "vitality"},
        headers=_auth(tokens),
    )

    r = await client.get("/api/v1/goals?category=intelligence", headers=_auth(tokens))
    assert r.json()["total"] == 1

    r = await client.get("/api/v1/goals?category=vitality", headers=_auth(tokens))
    assert r.json()["total"] == 1


# ── Get by ID ──────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_get_goal_by_id(client: AsyncClient):
    tokens = await _register(client, "goal_getbyid@example.com")
    created = (
        await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens))
    ).json()

    r = await client.get(f"/api/v1/goals/{created['id']}", headers=_auth(tokens))
    assert r.status_code == 200
    assert r.json()["id"] == created["id"]


@pytest.mark.asyncio
async def test_get_goal_other_users_goal_returns_404(client: AsyncClient):
    tokens_a = await _register(client, "goal_owner@example.com")
    tokens_b = await _register(client, "goal_thief@example.com")

    goal = (
        await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens_a))
    ).json()

    r = await client.get(f"/api/v1/goals/{goal['id']}", headers=_auth(tokens_b))
    assert r.status_code == 404


# ── Update ─────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_update_goal_title(client: AsyncClient):
    tokens = await _register(client, "goal_update@example.com")
    goal = (
        await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens))
    ).json()

    r = await client.patch(
        f"/api/v1/goals/{goal['id']}",
        json={"title": "Read 24 books this year"},
        headers=_auth(tokens),
    )
    assert r.status_code == 200
    assert r.json()["title"] == "Read 24 books this year"


@pytest.mark.asyncio
async def test_update_goal_status_to_abandoned(client: AsyncClient):
    tokens = await _register(client, "goal_abandon@example.com")
    goal = (
        await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens))
    ).json()

    r = await client.patch(
        f"/api/v1/goals/{goal['id']}",
        json={"status": "abandoned"},
        headers=_auth(tokens),
    )
    assert r.status_code == 200
    assert r.json()["status"] == "abandoned"


# ── Complete ───────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_complete_goal_with_evidence(client: AsyncClient):
    tokens = await _register(client, "goal_complete@example.com")
    goal = (
        await client.post(
            "/api/v1/goals",
            json={**_GOAL_PAYLOAD, "difficulty": "hard"},
            headers=_auth(tokens),
        )
    ).json()

    r = await client.post(
        f"/api/v1/goals/{goal['id']}/complete",
        json={
            "evidence_text": "I finished all 12 books and kept detailed notes on each one.",
            "reflection": "Reading consistently improved my focus and vocabulary.",
            "effort_level": 4,
        },
        headers=_auth(tokens),
    )
    assert r.status_code == 200
    data = r.json()
    assert data["goal"]["status"] == "completed"
    assert data["goal"]["completion"] is not None
    assert data["goal"]["completion"]["effort_level"] == 4
    assert data["xp_awarded"] == 250  # hard * effort 4 = 200 * 1.25
    assert isinstance(data["levels_gained"], list)


@pytest.mark.asyncio
async def test_complete_goal_awards_xp_to_character(client: AsyncClient):
    tokens = await _register(client, "goal_xp_award@example.com")
    goal = (
        await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens))
    ).json()

    await client.post(
        f"/api/v1/goals/{goal['id']}/complete",
        json={
            "evidence_text": "Finished every book I planned to read this month — tracked in Notion.",
            "effort_level": 3,
        },
        headers=_auth(tokens),
    )

    char = (
        await client.get("/api/v1/character", headers=_auth(tokens))
    ).json()
    assert char["total_xp"] == 100  # medium * effort 3
    assert char["stats"]["intelligence"] == 1  # stat incremented


@pytest.mark.asyncio
async def test_complete_goal_evidence_too_short(client: AsyncClient):
    tokens = await _register(client, "goal_shortevidence@example.com")
    goal = (
        await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens))
    ).json()

    r = await client.post(
        f"/api/v1/goals/{goal['id']}/complete",
        json={"evidence_text": "Done", "effort_level": 3},
        headers=_auth(tokens),
    )
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_complete_already_completed_goal_returns_409(client: AsyncClient):
    tokens = await _register(client, "goal_double_complete@example.com")
    goal = (
        await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens))
    ).json()

    evidence = {
        "evidence_text": "I completed this goal fully and documented everything carefully.",
        "effort_level": 3,
    }
    await client.post(f"/api/v1/goals/{goal['id']}/complete", json=evidence, headers=_auth(tokens))

    r = await client.post(
        f"/api/v1/goals/{goal['id']}/complete", json=evidence, headers=_auth(tokens)
    )
    assert r.status_code == 409


# ── Delete (archive) ───────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_delete_goal_archives_it(client: AsyncClient):
    tokens = await _register(client, "goal_delete@example.com")
    goal = (
        await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens))
    ).json()

    r = await client.delete(f"/api/v1/goals/{goal['id']}", headers=_auth(tokens))
    assert r.status_code == 204

    r = await client.get(f"/api/v1/goals/{goal['id']}", headers=_auth(tokens))
    assert r.json()["status"] == "archived"


@pytest.mark.asyncio
async def test_delete_is_idempotent(client: AsyncClient):
    tokens = await _register(client, "goal_delete_idem@example.com")
    goal = (
        await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens))
    ).json()

    await client.delete(f"/api/v1/goals/{goal['id']}", headers=_auth(tokens))
    r = await client.delete(f"/api/v1/goals/{goal['id']}", headers=_auth(tokens))
    assert r.status_code == 204


# ── Goals are user-scoped ──────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_goals_are_isolated_between_users(client: AsyncClient):
    tokens_a = await _register(client, "goal_iso_a@example.com")
    tokens_b = await _register(client, "goal_iso_b@example.com")

    await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens_a))

    r = await client.get("/api/v1/goals", headers=_auth(tokens_b))
    assert r.json()["total"] == 0
