import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, computed_field

from app.core.xp_engine import xp_for_level


class StatSnapshot(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    vitality: int
    strength: int
    intelligence: int
    wisdom: int
    charisma: int
    discipline: int


class CharacterResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    level: int
    rank: str
    total_xp: int
    current_level_xp: int
    stats: StatSnapshot | None = None

    @computed_field
    @property
    def xp_to_next_level(self) -> int:
        """Total XP required to complete the current level (for progress bar: current_level_xp / this)."""
        return xp_for_level(self.level)


class XPTransactionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    amount: int
    source_type: str
    stat_category: str | None
    description: str
    created_at: datetime


class XPHistoryResponse(BaseModel):
    transactions: list[XPTransactionResponse]
    total: int
    page: int
    page_size: int
