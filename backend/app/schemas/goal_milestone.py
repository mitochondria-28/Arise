import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class GoalMilestoneResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    goal_id: uuid.UUID
    title: str
    description: str | None
    is_completed: bool
    sort_order: int
    created_at: datetime
    updated_at: datetime


class CreateMilestoneRequest(BaseModel):
    title: str = Field(..., min_length=3, max_length=200)
    description: str | None = Field(None, max_length=500)
    sort_order: int = Field(0, ge=0)


class UpdateMilestoneRequest(BaseModel):
    title: str | None = Field(None, min_length=3, max_length=200)
    description: str | None = None
    is_completed: bool | None = None
    sort_order: int | None = Field(None, ge=0)
