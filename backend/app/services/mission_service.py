import uuid
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import ConflictError, ValidationError
from app.core.mission_engine import (
    MISSION_FREQUENCIES,
    is_same_period,
    is_streak_maintained,
)
from app.core.xp_engine import GOAL_DIFFICULTIES, STAT_CATEGORIES, calculate_mission_xp
from app.repositories.character_repository import CharacterRepository
from app.repositories.mission_repository import MissionLogRepository, MissionRepository
from app.schemas.mission import (
    CheckinResponse,
    MissionListResponse,
    MissionLogListResponse,
    MissionLogResponse,
    MissionResponse,
)
from app.services.character_service import CharacterService


class MissionService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._missions = MissionRepository(db)
        self._logs = MissionLogRepository(db)

    async def create(
        self,
        user_id: uuid.UUID,
        *,
        title: str,
        category: str,
        difficulty: str,
        frequency: str,
        description: str | None = None,
        target_count: int = 0,
    ) -> MissionResponse:
        if category not in STAT_CATEGORIES:
            raise ValidationError(f"Unknown category: {category!r}.")
        if difficulty not in GOAL_DIFFICULTIES:
            raise ValidationError(f"Unknown difficulty: {difficulty!r}.")
        if frequency not in MISSION_FREQUENCIES:
            raise ValidationError(f"Unknown frequency: {frequency!r}.")

        mission = await self._missions.create(
            user_id=user_id,
            title=title,
            description=description,
            category=category,
            difficulty=difficulty,
            frequency=frequency,
            target_count=target_count,
        )
        return MissionResponse.model_validate(mission)

    async def list_for_user(
        self,
        user_id: uuid.UUID,
        *,
        status: str | None = None,
        category: str | None = None,
        frequency: str | None = None,
        page: int = 1,
        page_size: int = 20,
    ) -> MissionListResponse:
        missions, total = await self._missions.list_by_user(
            user_id,
            status=status,
            category=category,
            frequency=frequency,
            page=page,
            page_size=page_size,
        )
        return MissionListResponse(
            missions=[MissionResponse.model_validate(m) for m in missions],
            total=total,
            page=page,
            page_size=page_size,
        )

    async def get_by_id(self, mission_id: uuid.UUID, user_id: uuid.UUID) -> MissionResponse:
        mission = await self._missions.get_by_id(mission_id, user_id=user_id)
        return MissionResponse.model_validate(mission)

    async def update(
        self,
        mission_id: uuid.UUID,
        user_id: uuid.UUID,
        **fields: object,
    ) -> MissionResponse:
        mission = await self._missions.get_by_id(mission_id, user_id=user_id)

        if fields.get("status") and mission.status == "completed":
            raise ConflictError("A completed mission's status cannot be changed.")

        updates = {k: v for k, v in fields.items() if v is not None}
        if updates:
            mission = await self._missions.update(mission, **updates)
        return MissionResponse.model_validate(mission)

    async def checkin(
        self,
        mission_id: uuid.UUID,
        user_id: uuid.UUID,
        *,
        evidence_text: str,
        reflection: str | None,
        effort_level: int,
    ) -> CheckinResponse:
        mission = await self._missions.get_by_id(mission_id, user_id=user_id)

        if mission.status != "active":
            raise ConflictError(
                f"Only active missions can be checked in (current: '{mission.status}')."
            )

        if mission.last_completed_at and is_same_period(
            mission.last_completed_at, mission.frequency
        ):
            raise ConflictError(
                f"Already checked in this {mission.frequency} period."
            )

        new_streak = (
            mission.current_streak + 1
            if mission.last_completed_at
            and is_streak_maintained(mission.last_completed_at, mission.frequency)
            else 1
        )
        longest = max(mission.longest_streak, new_streak)
        xp_awarded = calculate_mission_xp(mission.difficulty, effort_level, new_streak)
        new_count = mission.completion_count + 1
        new_status = (
            "completed"
            if mission.target_count > 0 and new_count >= mission.target_count
            else mission.status
        )

        log = await self._logs.create(
            mission_id=mission_id,
            evidence_text=evidence_text,
            reflection=reflection,
            effort_level=effort_level,
            xp_awarded=xp_awarded,
            streak_at_checkin=new_streak,
        )

        mission = await self._missions.update(
            mission,
            current_streak=new_streak,
            longest_streak=longest,
            completion_count=new_count,
            last_completed_at=datetime.now(timezone.utc),
            status=new_status,
        )

        character = await CharacterRepository(self._db).get_by_user_id(user_id)
        levels_gained: list[int] = []
        if character:
            _, levels_gained = await CharacterService(self._db).award_xp(
                character.id,
                xp_awarded,
                "mission",
                source_id=mission_id,
                stat_category=mission.category,
                description=f"Mission check-in: {mission.title} (streak {new_streak})",
            )

        return CheckinResponse(
            mission=MissionResponse.model_validate(mission),
            log=MissionLogResponse.model_validate(log),
            xp_awarded=xp_awarded,
            new_streak=new_streak,
            levels_gained=levels_gained,
        )

    async def get_logs(
        self,
        mission_id: uuid.UUID,
        user_id: uuid.UUID,
        *,
        page: int = 1,
        page_size: int = 20,
    ) -> MissionLogListResponse:
        await self._missions.get_by_id(mission_id, user_id=user_id)
        logs, total = await self._logs.list_by_mission(
            mission_id, page=page, page_size=page_size
        )
        return MissionLogListResponse(
            logs=[MissionLogResponse.model_validate(lg) for lg in logs],
            total=total,
            page=page,
            page_size=page_size,
        )

    async def archive(self, mission_id: uuid.UUID, user_id: uuid.UUID) -> None:
        mission = await self._missions.get_by_id(mission_id, user_id=user_id)
        if mission.status != "archived":
            await self._missions.update(mission, status="archived")
