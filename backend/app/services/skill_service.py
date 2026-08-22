import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError
from app.models.skill import UserSkill
from app.repositories.character_repository import CharacterRepository
from app.repositories.skill_repository import SkillRepository, UserSkillRepository
from app.schemas.skill import (
    PracticeResponse,
    SkillResponse,
    UserSkillResponse,
)
from app.services.character_service import CharacterService

# Cumulative session thresholds to reach each level (index = level, value = sessions needed)
# L1=0, L2=5, L3=15, L4=30, L5=50, L6=75, L7=105, L8=140, L9=180, L10=225
_THRESHOLDS = [0, 0, 5, 15, 30, 50, 75, 105, 140, 180, 225]
MAX_LEVEL = 10


def _level_for_sessions(session_count: int) -> int:
    level = 1
    for lvl in range(2, MAX_LEVEL + 1):
        if session_count >= _THRESHOLDS[lvl]:
            level = lvl
        else:
            break
    return level


def _sessions_to_next_level(level: int, session_count: int) -> int:
    if level >= MAX_LEVEL:
        return 0
    return _THRESHOLDS[level + 1] - session_count


def _xp_per_session(level: int) -> int:
    return 30 + (level - 1) * 10


def _to_user_skill_response(us: UserSkill) -> UserSkillResponse:
    return UserSkillResponse(
        id=us.id,
        user_id=us.user_id,
        skill_id=us.skill_id,
        level=us.level,
        session_count=us.session_count,
        total_xp_earned=us.total_xp_earned,
        last_practiced_at=us.last_practiced_at,
        skill=SkillResponse.model_validate(us.skill),
        sessions_to_next_level=_sessions_to_next_level(us.level, us.session_count),
        xp_per_session=_xp_per_session(us.level),
    )


class SkillService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._skills = SkillRepository(db)
        self._user_skills = UserSkillRepository(db)
        self._chars = CharacterService(db)
        self._char_repo = CharacterRepository(db)

    async def list_catalog(self, category: str | None = None) -> list[SkillResponse]:
        skills = await self._skills.list_all(category=category)
        return [SkillResponse.model_validate(s) for s in skills]

    async def get_user_skills(self, user_id: uuid.UUID) -> list[UserSkillResponse]:
        user_skills = await self._user_skills.list_by_user(user_id)
        return [_to_user_skill_response(us) for us in user_skills]

    async def unlock(self, user_id: uuid.UUID, skill_id: uuid.UUID) -> UserSkillResponse:
        await self._skills.get_by_id(skill_id)
        us = await self._user_skills.create(user_id, skill_id)
        return _to_user_skill_response(us)

    async def practice(
        self,
        user_id: uuid.UUID,
        skill_id: uuid.UUID,
        *,
        notes: str,
        duration_minutes: int | None = None,
    ) -> PracticeResponse:
        us = await self._user_skills.get(user_id, skill_id)
        if us is None:
            raise NotFoundError("UserSkill", str(skill_id))

        new_session_count = us.session_count + 1
        new_level = _level_for_sessions(new_session_count)
        levels_gained = list(range(us.level + 1, new_level + 1)) if new_level > us.level else []

        xp_awarded = _xp_per_session(us.level)
        if duration_minutes:
            xp_awarded = int(xp_awarded * min(duration_minutes / 30, 2.0))

        await self._user_skills.record_practice(
            us,
            new_level=new_level,
            new_session_count=new_session_count,
            xp_earned=xp_awarded,
        )

        character = await self._char_repo.get_by_user_id(user_id)
        if character:
            await self._chars.award_xp(
                character.id,
                xp_awarded,
                "skill_practice",
                stat_category=us.skill.category,
                description=f"Practiced {us.skill.name}: {notes[:80]}",
                meta={"skill_id": str(skill_id), "duration_minutes": duration_minutes},
            )

        await self._db.commit()
        await self._db.refresh(us, ["skill"])

        return PracticeResponse(
            user_skill=_to_user_skill_response(us),
            xp_awarded=xp_awarded,
            levels_gained=levels_gained,
            leveled_up=bool(levels_gained),
        )
