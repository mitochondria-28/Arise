import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError, ValidationError
from app.core.xp_engine import STAT_CATEGORIES, apply_xp, rank_for_level
from app.models.character import Character
from app.models.xp_transaction import XPTransaction
from app.repositories.character_repository import (
    CharacterRepository,
    CharacterStatsRepository,
    XPTransactionRepository,
)
from app.repositories.stat_snapshot_repository import StatSnapshotRepository


class CharacterService:
    def __init__(self, db: AsyncSession) -> None:
        self._chars = CharacterRepository(db)
        self._stats_repo = CharacterStatsRepository(db)
        self._txns = XPTransactionRepository(db)
        self._snapshots = StatSnapshotRepository(db)

    async def create_for_user(self, user_id: uuid.UUID) -> Character:
        character = await self._chars.create(user_id=user_id)
        await self._stats_repo.create(character_id=character.id)
        return character

    async def get_for_user(self, user_id: uuid.UUID) -> Character:
        character = await self._chars.get_by_user_id(user_id, load_stats=True)
        if not character:
            raise NotFoundError("Character", str(user_id))
        return character

    async def award_xp(
        self,
        character_id: uuid.UUID,
        amount: int,
        source_type: str,
        *,
        stat_category: str | None = None,
        description: str,
        source_id: uuid.UUID | None = None,
        meta: dict | None = None,
    ) -> tuple[Character, list[int]]:
        """
        Award XP to a character.  Called only by internal systems (goals, missions) —
        never exposed as a user-facing endpoint.

        Returns the updated Character and a list of levels gained (empty if no level-up).
        """
        if stat_category and stat_category not in STAT_CATEGORIES:
            raise ValidationError(f"Unknown stat category: {stat_category!r}.")

        character = await self._chars.get_by_id(character_id, load_stats=True)
        if not character:
            raise NotFoundError("Character", str(character_id))

        new_level, new_level_xp, new_total_xp, levels_gained = apply_xp(
            character.level, character.current_level_xp, character.total_xp, amount
        )
        new_rank = rank_for_level(new_level)

        character = await self._chars.update(
            character,
            level=new_level,
            current_level_xp=new_level_xp,
            total_xp=new_total_xp,
            rank=new_rank,
        )

        await self._txns.create(
            character_id=character_id,
            amount=amount,
            source_type=source_type,
            source_id=source_id,
            stat_category=stat_category,
            description=description,
            meta=meta,
        )

        if stat_category and character.stats:
            await self._stats_repo.increment_stat(character.stats, stat_category)

        # Daily snapshot — idempotent upsert
        if character.stats:
            s = character.stats
            await self._snapshots.upsert_today(
                character_id=character_id,
                vitality=s.vitality,
                strength=s.strength,
                intelligence=s.intelligence,
                wisdom=s.wisdom,
                charisma=s.charisma,
                discipline=s.discipline,
                total_xp=new_total_xp,
                level=new_level,
            )

        return character, levels_gained

    async def get_xp_history(
        self,
        character_id: uuid.UUID,
        *,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[XPTransaction], int]:
        return await self._txns.list_by_character(
            character_id, page=page, page_size=page_size
        )
