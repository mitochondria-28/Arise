import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.achievement_definitions import ACHIEVEMENTS, AchievementDef, qualifies
from app.models.goal import Goal
from app.models.mission import Mission
from app.repositories.achievement_repository import AchievementRepository
from app.services.character_service import CharacterService


class AchievementService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._repo = AchievementRepository(db)
        self._chars = CharacterService(db)

    async def list_with_status(
        self, user_id: uuid.UUID
    ) -> list[tuple[AchievementDef, str | None]]:
        """Return (definition, unlocked_at_iso | None) for every achievement."""
        unlocked = await self._repo.get_unlocked(user_id)
        return [
            (ach, unlocked[ach.key].isoformat() if ach.key in unlocked else None)
            for ach in ACHIEVEMENTS
        ]

    async def sync(self, user_id: uuid.UUID) -> list[tuple[AchievementDef, str]]:
        """
        Check all achievements against current user state.
        Award any that are now earned but not yet unlocked.
        Returns the newly unlocked achievements with their unlock timestamps.
        """
        character = await self._chars.get_for_user(user_id)
        already_unlocked = await self._repo.get_unlocked(user_id)

        # Gather current stats
        total_xp = character.total_xp
        level = character.level
        rank = character.rank

        goals_completed = await self._count_goals_completed(user_id)
        best_streak, total_checkins = await self._mission_stats(user_id)

        newly_earned = [
            ach
            for ach in ACHIEVEMENTS
            if ach.key not in already_unlocked
            and qualifies(
                ach,
                total_xp=total_xp,
                goals_completed=goals_completed,
                best_streak=best_streak,
                total_checkins=total_checkins,
                level=level,
                rank=rank,
            )
        ]

        if newly_earned:
            await self._repo.award_many(user_id, [a.key for a in newly_earned])
            await self._db.commit()

        # Re-fetch so timestamps come from DB
        refreshed = await self._repo.get_unlocked(user_id)
        return [
            (ach, refreshed[ach.key].isoformat())
            for ach in newly_earned
            if ach.key in refreshed
        ]

    # ── private helpers ────────────────────────────────────────────────────────

    async def _count_goals_completed(self, user_id: uuid.UUID) -> int:
        stmt = select(func.count()).where(
            Goal.user_id == user_id,
            Goal.status == "completed",
        )
        result = await self._db.execute(stmt)
        return int(result.scalar() or 0)

    async def _mission_stats(self, user_id: uuid.UUID) -> tuple[int, int]:
        """Return (best_streak, total_checkins) across all user missions."""
        stmt = select(
            func.coalesce(func.max(Mission.longest_streak), 0).label("best"),
            func.coalesce(func.sum(Mission.completion_count), 0).label("checkins"),
        ).where(Mission.user_id == user_id)
        row = (await self._db.execute(stmt)).one()
        return int(row.best), int(row.checkins)
