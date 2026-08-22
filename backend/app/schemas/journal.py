from __future__ import annotations

import uuid
from datetime import date, datetime

from pydantic import BaseModel, Field, field_validator


class CreateJournalRequest(BaseModel):
    content: str = Field(..., min_length=20, max_length=10_000)
    mood: int | None = Field(None, ge=1, le=5)
    entry_date: date | None = None  # defaults to today server-side


class UpdateJournalRequest(BaseModel):
    content: str = Field(..., min_length=20, max_length=10_000)
    mood: int | None = Field(None, ge=1, le=5)


class JournalEntryResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    entry_date: date
    content: str
    mood: int | None
    ai_reflection: str | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class JournalListResponse(BaseModel):
    entries: list[JournalEntryResponse]
    total: int
    streak: int


class JournalStreakResponse(BaseModel):
    streak: int
    total_entries: int
