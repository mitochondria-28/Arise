import logging
import uuid

from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.gemini import gemini_client
from app.models.ai_analysis import AIAnalysis
from app.models.character import Character
from app.models.goal import Goal
from app.models.mission import Mission
from app.models.user_profile import UserProfile
from app.repositories.ai_repository import AIAnalysisRepository
from app.repositories.character_repository import CharacterRepository

logger = logging.getLogger(__name__)


class AIService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._ai_repo = AIAnalysisRepository(db)

    async def _get_display_name(self, user_id: uuid.UUID) -> str:
        result = await self._db.execute(
            select(UserProfile).where(UserProfile.user_id == user_id)
        )
        profile = result.scalar_one_or_none()
        return profile.display_name if (profile and profile.display_name) else "Hunter"

    async def generate_growth_report(
        self,
        *,
        character_id: uuid.UUID,
        user_id: uuid.UUID,
    ) -> AIAnalysis | None:
        char_result = await self._db.execute(
            select(Character)
            .options(selectinload(Character.stats))
            .where(Character.id == character_id)
        )
        character = char_result.scalar_one_or_none()
        if not character:
            return None

        display_name = await self._get_display_name(user_id)

        goals_result = await self._db.execute(
            select(Goal)
            .where(Goal.user_id == user_id, Goal.status == "completed")
            .order_by(Goal.completed_at.desc())
            .limit(5)
        )
        recent_goals = [g.title for g in goals_result.scalars().all()]

        missions_result = await self._db.execute(
            select(Mission)
            .where(Mission.user_id == user_id, Mission.status == "active")
            .order_by(Mission.current_streak.desc())
            .limit(5)
        )
        top_missions = [
            f"{m.title} (streak: {m.current_streak})"
            for m in missions_result.scalars().all()
        ]

        stats: dict[str, int] = {}
        if character.stats:
            stats = {
                "vitality": character.stats.vitality,
                "strength": character.stats.strength,
                "intelligence": character.stats.intelligence,
                "wisdom": character.stats.wisdom,
                "charisma": character.stats.charisma,
                "discipline": character.stats.discipline,
            }

        prompt = gemini_client.build_growth_report_prompt(
            display_name=display_name,
            level=character.level,
            rank=character.rank,
            total_xp=character.total_xp,
            stats=stats,
            recent_completions=recent_goals,
            top_missions=top_missions,
        )

        content = await gemini_client.generate(prompt)
        if content is None:
            return None

        return await self._ai_repo.create(
            character_id=character_id,
            source_type="growth_report",
            source_id=None,
            prompt=prompt,
            content=content,
            model_used=settings.GEMINI_MODEL,
        )


# ── Background task functions ─────────────────────────────────────────────────
#
# Background tasks run BEFORE the request session commits (FastAPI's DI
# cleanup runs after Starlette sends the response + background tasks).
# To avoid reading uncommitted data, we receive all completion-specific
# values from the route and only query for stable data (character / profile)
# that was committed long before this request started.

async def analyze_goal_bg(
    *,
    user_id: uuid.UUID,
    goal_id: uuid.UUID,
    goal_title: str,
    goal_category: str,
    goal_difficulty: str,
    evidence_text: str,
    reflection: str | None,
    effort_level: int,
    xp_awarded: int,
) -> None:
    from app.database.session import get_async_session_context

    try:
        async with get_async_session_context() as db:
            character = await CharacterRepository(db).get_by_user_id(
                user_id, load_stats=False
            )
            if not character:
                return
            profile_result = await db.execute(
                select(UserProfile).where(UserProfile.user_id == user_id)
            )
            profile = profile_result.scalar_one_or_none()
            display_name = (
                profile.display_name if (profile and profile.display_name) else "Hunter"
            )

        prompt = gemini_client.build_goal_prompt(
            display_name=display_name,
            goal_title=goal_title,
            goal_category=goal_category,
            goal_difficulty=goal_difficulty,
            evidence_text=evidence_text,
            reflection=reflection,
            effort_level=effort_level,
            xp_awarded=xp_awarded,
        )
        content = await gemini_client.generate(prompt)
        if content is None:
            return

        async with get_async_session_context() as db:
            await AIAnalysisRepository(db).create(
                character_id=character.id,
                source_type="goal",
                source_id=goal_id,
                prompt=prompt,
                content=content,
                model_used=settings.GEMINI_MODEL,
            )
    except Exception as exc:
        logger.error("Background goal analysis failed (goal_id=%s): %s", goal_id, exc)


async def analyze_mission_bg(
    *,
    user_id: uuid.UUID,
    mission_id: uuid.UUID,
    mission_title: str,
    mission_category: str,
    mission_frequency: str,
    evidence_text: str,
    reflection: str | None,
    effort_level: int,
    xp_awarded: int,
    streak_at_checkin: int,
) -> None:
    from app.database.session import get_async_session_context

    try:
        async with get_async_session_context() as db:
            character = await CharacterRepository(db).get_by_user_id(
                user_id, load_stats=False
            )
            if not character:
                return
            profile_result = await db.execute(
                select(UserProfile).where(UserProfile.user_id == user_id)
            )
            profile = profile_result.scalar_one_or_none()
            display_name = (
                profile.display_name if (profile and profile.display_name) else "Hunter"
            )

        prompt = gemini_client.build_mission_prompt(
            display_name=display_name,
            mission_title=mission_title,
            mission_category=mission_category,
            mission_frequency=mission_frequency,
            current_streak=streak_at_checkin,
            evidence_text=evidence_text,
            reflection=reflection,
            effort_level=effort_level,
            xp_awarded=xp_awarded,
        )
        content = await gemini_client.generate(prompt)
        if content is None:
            return

        async with get_async_session_context() as db:
            await AIAnalysisRepository(db).create(
                character_id=character.id,
                source_type="mission",
                source_id=mission_id,
                prompt=prompt,
                content=content,
                model_used=settings.GEMINI_MODEL,
            )
    except Exception as exc:
        logger.error(
            "Background mission analysis failed (mission_id=%s): %s", mission_id, exc
        )
