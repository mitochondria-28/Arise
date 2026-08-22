"""
Integration tests for the AI analysis layer.

Gemini is mocked via patch.object so no API key is needed.
BackgroundTasks run synchronously within the ASGI call, so the analysis
is available in the DB immediately after the triggering request completes.
"""
from unittest.mock import AsyncMock, patch

import pytest
from httpx import AsyncClient

from app.core.gemini import gemini_client

_MOCK_GOAL_ANALYSIS = "You demonstrated genuine discipline by completing all 12 chapters with annotations."
_MOCK_MISSION_ANALYSIS = "Maintaining a 10-day streak shows strong habit formation. Keep the momentum."
_MOCK_GROWTH_REPORT = "Your intelligence stat leads all others — consider balancing with vitality work."

_GOAL_PAYLOAD = {
    "title": "Read Atomic Habits",
    "category": "intelligence",
    "difficulty": "medium",
}
_MISSION_PAYLOAD = {
    "title": "Morning stretching",
    "category": "vitality",
    "difficulty": "easy",
    "frequency": "daily",
}
_COMPLETE_PAYLOAD = {
    "evidence_text": "Finished the book and wrote a 500-word summary with key takeaways.",
    "effort_level": 4,
}
_CHECKIN_PAYLOAD = {
    "evidence_text": "Stretched for 15 minutes following the YouTube routine I bookmarked.",
    "effort_level": 2,
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


# ── Goal analysis ──────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_goal_analysis_stored_after_completion(client: AsyncClient):
    with patch.object(
        gemini_client, "generate", new=AsyncMock(return_value=_MOCK_GOAL_ANALYSIS)
    ):
        tokens = await _register(client, "ai_goal_analysis@example.com")
        goal = (
            await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens))
        ).json()

        await client.post(
            f"/api/v1/goals/{goal['id']}/complete",
            json=_COMPLETE_PAYLOAD,
            headers=_auth(tokens),
        )

        r = await client.get(
            f"/api/v1/ai/analysis/goal/{goal['id']}", headers=_auth(tokens)
        )
        assert r.status_code == 200
        data = r.json()
        assert data["content"] == _MOCK_GOAL_ANALYSIS
        assert data["source_type"] == "goal"
        assert data["source_id"] == goal["id"]
        assert data["model_used"] == "gemini-2.0-flash"


@pytest.mark.asyncio
async def test_goal_analysis_not_found_before_completion(client: AsyncClient):
    tokens = await _register(client, "ai_goal_no_analysis@example.com")
    goal = (
        await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens))
    ).json()

    r = await client.get(
        f"/api/v1/ai/analysis/goal/{goal['id']}", headers=_auth(tokens)
    )
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_goal_analysis_other_user_is_404(client: AsyncClient):
    with patch.object(
        gemini_client, "generate", new=AsyncMock(return_value=_MOCK_GOAL_ANALYSIS)
    ):
        tokens_a = await _register(client, "ai_goal_owner@example.com")
        tokens_b = await _register(client, "ai_goal_other@example.com")

        goal = (
            await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens_a))
        ).json()
        await client.post(
            f"/api/v1/goals/{goal['id']}/complete",
            json=_COMPLETE_PAYLOAD,
            headers=_auth(tokens_a),
        )

        r = await client.get(
            f"/api/v1/ai/analysis/goal/{goal['id']}", headers=_auth(tokens_b)
        )
        assert r.status_code == 404


@pytest.mark.asyncio
async def test_goal_analysis_skipped_when_gemini_returns_none(client: AsyncClient):
    """When Gemini isn't configured (returns None), no analysis is stored."""
    with patch.object(
        gemini_client, "generate", new=AsyncMock(return_value=None)
    ):
        tokens = await _register(client, "ai_goal_no_key@example.com")
        goal = (
            await client.post("/api/v1/goals", json=_GOAL_PAYLOAD, headers=_auth(tokens))
        ).json()
        await client.post(
            f"/api/v1/goals/{goal['id']}/complete",
            json=_COMPLETE_PAYLOAD,
            headers=_auth(tokens),
        )

        r = await client.get(
            f"/api/v1/ai/analysis/goal/{goal['id']}", headers=_auth(tokens)
        )
        assert r.status_code == 404


# ── Mission analysis ───────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_mission_analysis_stored_after_checkin(client: AsyncClient):
    with patch.object(
        gemini_client, "generate", new=AsyncMock(return_value=_MOCK_MISSION_ANALYSIS)
    ):
        tokens = await _register(client, "ai_mission_analysis@example.com")
        mission = (
            await client.post(
                "/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens)
            )
        ).json()

        await client.post(
            f"/api/v1/missions/{mission['id']}/checkin",
            json=_CHECKIN_PAYLOAD,
            headers=_auth(tokens),
        )

        r = await client.get(
            f"/api/v1/ai/analysis/mission/{mission['id']}", headers=_auth(tokens)
        )
        assert r.status_code == 200
        data = r.json()
        assert data["content"] == _MOCK_MISSION_ANALYSIS
        assert data["source_type"] == "mission"
        assert data["source_id"] == mission["id"]


@pytest.mark.asyncio
async def test_mission_analysis_not_found_before_checkin(client: AsyncClient):
    tokens = await _register(client, "ai_mission_no_analysis@example.com")
    mission = (
        await client.post(
            "/api/v1/missions", json=_MISSION_PAYLOAD, headers=_auth(tokens)
        )
    ).json()

    r = await client.get(
        f"/api/v1/ai/analysis/mission/{mission['id']}", headers=_auth(tokens)
    )
    assert r.status_code == 404


# ── Growth report ──────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_growth_report_generated_on_demand(client: AsyncClient):
    with patch.object(
        gemini_client, "generate", new=AsyncMock(return_value=_MOCK_GROWTH_REPORT)
    ):
        tokens = await _register(client, "ai_growth@example.com")

        r = await client.post("/api/v1/ai/growth-report", headers=_auth(tokens))
        assert r.status_code == 200
        data = r.json()
        assert data["content"] == _MOCK_GROWTH_REPORT
        assert data["source_type"] == "growth_report"
        assert data["source_id"] is None


@pytest.mark.asyncio
async def test_growth_report_unavailable_when_no_key(client: AsyncClient):
    with patch.object(
        gemini_client, "generate", new=AsyncMock(return_value=None)
    ):
        tokens = await _register(client, "ai_growth_nokey@example.com")
        r = await client.post("/api/v1/ai/growth-report", headers=_auth(tokens))
        assert r.status_code == 503


@pytest.mark.asyncio
async def test_growth_report_unauthenticated(client: AsyncClient):
    r = await client.post("/api/v1/ai/growth-report")
    assert r.status_code == 401
