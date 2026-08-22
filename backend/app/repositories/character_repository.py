import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.character import Character
from app.models.character_stats import CharacterStats
from app.models.xp_transaction import XPTransaction


class CharacterRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_by_user_id(
        self, user_id: uuid.UUID, *, load_stats: bool = True
    ) -> Character | None:
        stmt = select(Character).where(Character.user_id == user_id)
        if load_stats:
            stmt = stmt.options(selectinload(Character.stats))
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_id(
        self, character_id: uuid.UUID, *, load_stats: bool = False
    ) -> Character | None:
        stmt = select(Character).where(Character.id == character_id)
        if load_stats:
            stmt = stmt.options(selectinload(Character.stats))
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def create(self, *, user_id: uuid.UUID) -> Character:
        character = Character(user_id=user_id)
        self.db.add(character)
        await self.db.flush()
        await self.db.refresh(character)
        return character

    async def update(self, character: Character, **fields: object) -> Character:
        for key, value in fields.items():
            setattr(character, key, value)
        await self.db.flush()
        await self.db.refresh(character)
        return character


class CharacterStatsRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create(self, *, character_id: uuid.UUID) -> CharacterStats:
        stats = CharacterStats(character_id=character_id)
        self.db.add(stats)
        await self.db.flush()
        await self.db.refresh(stats)
        return stats

    async def increment_stat(
        self, stats: CharacterStats, stat_category: str, amount: int = 1
    ) -> CharacterStats:
        current = getattr(stats, stat_category, 0)
        setattr(stats, stat_category, current + amount)
        await self.db.flush()
        await self.db.refresh(stats)
        return stats


class XPTransactionRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create(
        self,
        *,
        character_id: uuid.UUID,
        amount: int,
        source_type: str,
        description: str,
        source_id: uuid.UUID | None = None,
        stat_category: str | None = None,
        meta: dict | None = None,
    ) -> XPTransaction:
        txn = XPTransaction(
            character_id=character_id,
            amount=amount,
            source_type=source_type,
            source_id=source_id,
            stat_category=stat_category,
            description=description,
            meta=meta,
        )
        self.db.add(txn)
        await self.db.flush()
        await self.db.refresh(txn)
        return txn

    async def list_by_character(
        self,
        character_id: uuid.UUID,
        *,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[XPTransaction], int]:
        offset = (page - 1) * page_size

        count_stmt = (
            select(func.count())
            .select_from(XPTransaction)
            .where(XPTransaction.character_id == character_id)
        )
        total: int = (await self.db.execute(count_stmt)).scalar_one()

        stmt = (
            select(XPTransaction)
            .where(XPTransaction.character_id == character_id)
            .order_by(XPTransaction.created_at.desc())
            .limit(page_size)
            .offset(offset)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all()), total
