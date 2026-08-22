import uuid
from datetime import date, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import ConflictError, NotFoundError, ValidationError
from app.core.gemini import gemini_client
from app.models.journal import JournalEntry
from app.models.user_profile import UserProfile
from app.repositories.journal_repository import JournalRepository


class JournalService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._repo = JournalRepository(db)

    async def create_or_update(
        self,
        user_id: uuid.UUID,
        *,
        content: str,
        mood: int | None,
        entry_date: date | None,
    ) -> JournalEntry:
        today = entry_date or date.today()

        existing = await self._repo.get_by_date(user_id, today)
        if existing:
            entry = await self._repo.update_content(existing, content=content, mood=mood)
        else:
            entry = await self._repo.create(
                user_id, entry_date=today, content=content, mood=mood
            )
        await self._db.commit()
        return entry

    async def update(
        self,
        entry_id: uuid.UUID,
        user_id: uuid.UUID,
        *,
        content: str,
        mood: int | None,
    ) -> JournalEntry:
        entry = await self._repo.get_by_id(entry_id, user_id)
        if not entry:
            raise NotFoundError("Journal entry not found")
        entry = await self._repo.update_content(entry, content=content, mood=mood)
        await self._db.commit()
        return entry

    async def get_today(self, user_id: uuid.UUID) -> JournalEntry | None:
        return await self._repo.get_by_date(user_id, date.today())

    async def list_entries(
        self, user_id: uuid.UUID, *, limit: int = 30, offset: int = 0
    ) -> tuple[list[JournalEntry], int, int]:
        entries = await self._repo.list_recent(user_id, limit=limit, offset=offset)
        total = await self._repo.count(user_id)
        streak = await self._repo.get_streak(user_id)
        return entries, total, streak

    async def generate_reflection(
        self,
        entry_id: uuid.UUID,
        user_id: uuid.UUID,
    ) -> JournalEntry:
        entry = await self._repo.get_by_id(entry_id, user_id)
        if not entry:
            raise NotFoundError("Journal entry not found")

        display_name = await self._get_display_name(user_id)
        prompt = gemini_client.build_journal_prompt(
            display_name=display_name,
            entry_date=entry.entry_date.isoformat(),
            content=entry.content,
            mood=entry.mood,
        )
        reflection = await gemini_client.generate(prompt)
        if reflection is None:
            raise ValidationError(
                "AI reflection is not available — configure GEMINI_API_KEY to enable it"
            )

        entry = await self._repo.set_reflection(entry, reflection)
        await self._db.commit()
        return entry

    async def _get_display_name(self, user_id: uuid.UUID) -> str:
        result = await self._db.execute(
            select(UserProfile).where(UserProfile.user_id == user_id)
        )
        profile = result.scalar_one_or_none()
        return profile.display_name if (profile and profile.display_name) else "Hunter"
