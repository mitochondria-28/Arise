import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError
from app.models.mission import Mission
from app.models.mission_log import MissionLog


class MissionRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_by_id(
        self, mission_id: uuid.UUID, *, user_id: uuid.UUID | None = None
    ) -> Mission:
        result = await self.db.execute(
            select(Mission).where(Mission.id == mission_id)
        )
        mission = result.scalar_one_or_none()
        if not mission or (user_id and mission.user_id != user_id):
            raise NotFoundError("Mission", str(mission_id))
        return mission

    async def list_by_user(
        self,
        user_id: uuid.UUID,
        *,
        status: str | None = None,
        category: str | None = None,
        frequency: str | None = None,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[Mission], int]:
        filters = [Mission.user_id == user_id]
        if status:
            filters.append(Mission.status == status)
        if category:
            filters.append(Mission.category == category)
        if frequency:
            filters.append(Mission.frequency == frequency)

        total: int = (
            await self.db.execute(
                select(func.count()).select_from(Mission).where(*filters)
            )
        ).scalar_one()

        result = await self.db.execute(
            select(Mission)
            .where(*filters)
            .order_by(Mission.created_at.desc())
            .limit(page_size)
            .offset((page - 1) * page_size)
        )
        return list(result.scalars().all()), total

    async def create(
        self,
        *,
        user_id: uuid.UUID,
        title: str,
        category: str,
        difficulty: str,
        frequency: str,
        description: str | None = None,
        target_count: int = 0,
    ) -> Mission:
        mission = Mission(
            user_id=user_id,
            title=title,
            description=description,
            category=category,
            difficulty=difficulty,
            frequency=frequency,
            target_count=target_count,
        )
        self.db.add(mission)
        await self.db.flush()
        await self.db.refresh(mission)
        return mission

    async def update(self, mission: Mission, **fields: object) -> Mission:
        for key, value in fields.items():
            setattr(mission, key, value)
        await self.db.flush()
        await self.db.refresh(mission)
        return mission


class MissionLogRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create(
        self,
        *,
        mission_id: uuid.UUID,
        evidence_text: str,
        effort_level: int,
        xp_awarded: int,
        streak_at_checkin: int,
        reflection: str | None = None,
    ) -> MissionLog:
        log = MissionLog(
            mission_id=mission_id,
            evidence_text=evidence_text,
            reflection=reflection,
            effort_level=effort_level,
            xp_awarded=xp_awarded,
            streak_at_checkin=streak_at_checkin,
        )
        self.db.add(log)
        await self.db.flush()
        await self.db.refresh(log)
        return log

    async def list_by_mission(
        self,
        mission_id: uuid.UUID,
        *,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[MissionLog], int]:
        total: int = (
            await self.db.execute(
                select(func.count())
                .select_from(MissionLog)
                .where(MissionLog.mission_id == mission_id)
            )
        ).scalar_one()

        result = await self.db.execute(
            select(MissionLog)
            .where(MissionLog.mission_id == mission_id)
            .order_by(MissionLog.created_at.desc())
            .limit(page_size)
            .offset((page - 1) * page_size)
        )
        return list(result.scalars().all()), total
