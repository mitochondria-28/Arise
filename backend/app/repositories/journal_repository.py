import uuid
from datetime import date, timedelta

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.journal import JournalEntry


class JournalRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_by_date(
        self, user_id: uuid.UUID, entry_date: date
    ) -> JournalEntry | None:
        stmt = select(JournalEntry).where(
            JournalEntry.user_id == user_id,
            JournalEntry.entry_date == entry_date,
        )
        return (await self.db.execute(stmt)).scalar_one_or_none()

    async def get_by_id(
        self, entry_id: uuid.UUID, user_id: uuid.UUID
    ) -> JournalEntry | None:
        stmt = select(JournalEntry).where(
            JournalEntry.id == entry_id,
            JournalEntry.user_id == user_id,
        )
        return (await self.db.execute(stmt)).scalar_one_or_none()

    async def list_recent(
        self, user_id: uuid.UUID, *, limit: int = 30, offset: int = 0
    ) -> list[JournalEntry]:
        stmt = (
            select(JournalEntry)
            .where(JournalEntry.user_id == user_id)
            .order_by(JournalEntry.entry_date.desc())
            .limit(limit)
            .offset(offset)
        )
        return list((await self.db.execute(stmt)).scalars())

    async def count(self, user_id: uuid.UUID) -> int:
        stmt = select(func.count()).where(JournalEntry.user_id == user_id)
        return int((await self.db.execute(stmt)).scalar() or 0)

    async def create(
        self,
        user_id: uuid.UUID,
        *,
        entry_date: date,
        content: str,
        mood: int | None = None,
    ) -> JournalEntry:
        entry = JournalEntry(
            user_id=user_id,
            entry_date=entry_date,
            content=content,
            mood=mood,
        )
        self.db.add(entry)
        await self.db.flush()
        await self.db.refresh(entry)
        return entry

    async def update_content(
        self,
        entry: JournalEntry,
        *,
        content: str,
        mood: int | None,
    ) -> JournalEntry:
        entry.content = content
        entry.mood = mood
        await self.db.flush()
        await self.db.refresh(entry)
        return entry

    async def set_reflection(
        self, entry: JournalEntry, reflection: str
    ) -> JournalEntry:
        entry.ai_reflection = reflection
        await self.db.flush()
        await self.db.refresh(entry)
        return entry

    async def get_streak(self, user_id: uuid.UUID) -> int:
        """Count consecutive days with entries ending today (backwards from today)."""
        stmt = (
            select(JournalEntry.entry_date)
            .where(JournalEntry.user_id == user_id)
            .order_by(JournalEntry.entry_date.desc())
        )
        rows = list((await self.db.execute(stmt)).scalars())
        if not rows:
            return 0

        today = date.today()
        streak = 0
        expected = today
        for d in rows:
            if d == expected:
                streak += 1
                expected = d - timedelta(days=1)
            elif d == today - timedelta(days=1) and streak == 0:
                # allow streak if yesterday was the last entry (today not written yet)
                streak += 1
                expected = d - timedelta(days=1)
            else:
                break
        return streak
