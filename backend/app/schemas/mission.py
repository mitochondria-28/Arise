import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, computed_field

from app.core.mission_engine import is_same_period


class CreateMissionRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: str | None = Field(None, max_length=2000)
    category: Literal[
        "vitality", "strength", "intelligence", "wisdom", "charisma", "discipline"
    ]
    difficulty: Literal["easy", "medium", "hard", "epic"]
    frequency: Literal["daily", "weekly", "monthly"]
    target_count: int = Field(0, ge=0, description="0 = unlimited")


class UpdateMissionRequest(BaseModel):
    title: str | None = Field(None, min_length=1, max_length=200)
    description: str | None = Field(None, max_length=2000)
    target_count: int | None = Field(None, ge=0)
    # "completed" is auto-set when target_count is reached; not user-settable via PATCH.
    status: Literal["active", "paused", "archived"] | None = None


class CheckinRequest(BaseModel):
    evidence_text: str = Field(
        ...,
        min_length=20,
        max_length=5000,
        description="What you actually did — minimum 20 characters.",
    )
    reflection: str | None = Field(None, max_length=5000)
    effort_level: int = Field(..., ge=1, le=5)


class MissionLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    mission_id: uuid.UUID
    evidence_text: str
    reflection: str | None
    effort_level: int
    xp_awarded: int
    streak_at_checkin: int
    created_at: datetime


class MissionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    description: str | None
    category: str
    difficulty: str
    frequency: str
    status: str
    target_count: int
    completion_count: int
    current_streak: int
    longest_streak: int
    last_completed_at: datetime | None
    created_at: datetime
    updated_at: datetime

    @computed_field
    @property
    def can_checkin_now(self) -> bool:
        """Whether the user is eligible to check in right now."""
        if self.status != "active":
            return False
        if self.last_completed_at is None:
            return True
        return not is_same_period(self.last_completed_at, self.frequency)


class CheckinResponse(BaseModel):
    mission: MissionResponse
    log: MissionLogResponse
    xp_awarded: int
    new_streak: int
    levels_gained: list[int]


class MissionListResponse(BaseModel):
    missions: list[MissionResponse]
    total: int
    page: int
    page_size: int


class MissionLogListResponse(BaseModel):
    logs: list[MissionLogResponse]
    total: int
    page: int
    page_size: int
