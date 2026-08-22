import uuid
from datetime import datetime

from sqlalchemy import insert, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.achievement import UserAchievement


class AchievementRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_unlocked(self, user_id: uuid.UUID) -> dict[str, datetime]:
        """Return {achievement_key: unlocked_at} for every achievement the user holds."""
        stmt = select(
            UserAchievement.achievement_key,
            UserAchievement.unlocked_at,
        ).where(UserAchievement.user_id == user_id)
        rows = (await self.db.execute(stmt)).all()
        return {row.achievement_key: row.unlocked_at for row in rows}

    async def award_many(
        self, user_id: uuid.UUID, keys: list[str]
    ) -> None:
        """Insert unlock records for each key, ignoring duplicates."""
        if not keys:
            return
        await self.db.execute(
            insert(UserAchievement)
            .values([{"user_id": user_id, "achievement_key": k} for k in keys])
            .on_conflict_do_nothing(constraint="uq_user_achievement_key")
        )
        await self.db.flush()
