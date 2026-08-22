import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import ConflictError, NotFoundError
from app.models.skill import Skill, UserSkill


class SkillRepository:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def list_all(self, category: str | None = None) -> list[Skill]:
        stmt = select(Skill).order_by(Skill.sort_order)
        if category:
            stmt = stmt.where(Skill.category == category)
        result = await self._db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_id(self, skill_id: uuid.UUID) -> Skill:
        result = await self._db.execute(select(Skill).where(Skill.id == skill_id))
        skill = result.scalar_one_or_none()
        if not skill:
            raise NotFoundError("Skill", str(skill_id))
        return skill


class UserSkillRepository:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def list_by_user(self, user_id: uuid.UUID) -> list[UserSkill]:
        stmt = (
            select(UserSkill)
            .where(UserSkill.user_id == user_id)
            .options(selectinload(UserSkill.skill))
            .order_by(UserSkill.created_at)
        )
        result = await self._db.execute(stmt)
        return list(result.scalars().all())

    async def get(self, user_id: uuid.UUID, skill_id: uuid.UUID) -> UserSkill | None:
        stmt = (
            select(UserSkill)
            .where(UserSkill.user_id == user_id, UserSkill.skill_id == skill_id)
            .options(selectinload(UserSkill.skill))
        )
        result = await self._db.execute(stmt)
        return result.scalar_one_or_none()

    async def create(self, user_id: uuid.UUID, skill_id: uuid.UUID) -> UserSkill:
        existing = await self.get(user_id, skill_id)
        if existing:
            raise ConflictError("Skill already unlocked.")
        us = UserSkill(user_id=user_id, skill_id=skill_id)
        self._db.add(us)
        await self._db.flush()
        await self._db.refresh(us, ["skill"])
        return us

    async def record_practice(
        self,
        us: UserSkill,
        *,
        new_level: int,
        new_session_count: int,
        xp_earned: int,
    ) -> UserSkill:
        us.level = new_level
        us.session_count = new_session_count
        us.total_xp_earned += xp_earned
        us.last_practiced_at = datetime.now(timezone.utc)
        await self._db.flush()
        return us
