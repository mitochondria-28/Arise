import uuid
from datetime import date, timedelta

from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.postgresql import insert as pg_insert

from app.models.stat_snapshot import StatSnapshot


class StatSnapshotRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def upsert_today(
        self,
        *,
        character_id: uuid.UUID,
        vitality: int,
        strength: int,
        intelligence: int,
        wisdom: int,
        charisma: int,
        discipline: int,
        total_xp: int,
        level: int,
    ) -> StatSnapshot:
        today = date.today()
        stmt = (
            pg_insert(StatSnapshot)
            .values(
                id=uuid.uuid4(),
                character_id=character_id,
                snapshot_date=today,
                vitality=vitality,
                strength=strength,
                intelligence=intelligence,
                wisdom=wisdom,
                charisma=charisma,
                discipline=discipline,
                total_xp=total_xp,
                level=level,
            )
            .on_conflict_do_update(
                constraint="uq_stat_snapshots_character_date",
                set_={
                    "vitality": vitality,
                    "strength": strength,
                    "intelligence": intelligence,
                    "wisdom": wisdom,
                    "charisma": charisma,
                    "discipline": discipline,
                    "total_xp": total_xp,
                    "level": level,
                },
            )
            .returning(StatSnapshot)
        )
        result = await self.db.execute(stmt)
        return result.scalar_one()

    async def get_history(
        self,
        character_id: uuid.UUID,
        days: int = 30,
    ) -> list[StatSnapshot]:
        since = date.today() - timedelta(days=days - 1)
        result = await self.db.execute(
            select(StatSnapshot)
            .where(
                StatSnapshot.character_id == character_id,
                StatSnapshot.snapshot_date >= since,
            )
            .order_by(StatSnapshot.snapshot_date)
        )
        return list(result.scalars().all())
