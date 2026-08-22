import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class SkillResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    description: str
    category: str
    emoji: str
    sort_order: int


class UserSkillResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    skill_id: uuid.UUID
    level: int
    session_count: int
    total_xp_earned: int
    last_practiced_at: datetime | None
    skill: SkillResponse
    sessions_to_next_level: int
    xp_per_session: int


class PracticeRequest(BaseModel):
    notes: str = Field(..., min_length=10, max_length=500)
    duration_minutes: int | None = Field(None, ge=1, le=480)


class PracticeResponse(BaseModel):
    user_skill: UserSkillResponse
    xp_awarded: int
    levels_gained: list[int]
    leveled_up: bool
