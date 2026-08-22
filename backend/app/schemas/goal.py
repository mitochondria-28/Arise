import uuid
from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class CreateGoalRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: str | None = Field(None, max_length=2000)
    category: Literal[
        "vitality", "strength", "intelligence", "wisdom", "charisma", "discipline"
    ]
    difficulty: Literal["easy", "medium", "hard", "epic"]
    target_date: date | None = None


class UpdateGoalRequest(BaseModel):
    title: str | None = Field(None, min_length=1, max_length=200)
    description: str | None = Field(None, max_length=2000)
    target_date: date | None = None
    # Only "active" (reactivate) and "abandoned" are allowed via PATCH.
    # "completed" requires evidence; "archived" uses DELETE.
    status: Literal["active", "abandoned"] | None = None


class CompleteGoalRequest(BaseModel):
    evidence_text: str = Field(
        ...,
        min_length=20,
        max_length=5000,
        description="What you actually did — minimum 20 characters.",
    )
    reflection: str | None = Field(None, max_length=5000)
    effort_level: int = Field(..., ge=1, le=5)


class GoalCompletionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    goal_id: uuid.UUID
    evidence_text: str
    reflection: str | None
    effort_level: int
    xp_awarded: int
    created_at: datetime


class GoalResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    description: str | None
    category: str
    difficulty: str
    target_date: date | None
    status: str
    completed_at: datetime | None
    completion: GoalCompletionResponse | None = None
    created_at: datetime
    updated_at: datetime


class CompleteGoalResponse(BaseModel):
    goal: GoalResponse
    xp_awarded: int
    levels_gained: list[int]


class GoalListResponse(BaseModel):
    goals: list[GoalResponse]
    total: int
    page: int
    page_size: int
