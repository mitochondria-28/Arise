import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class AIMessageResponse(BaseModel):
    id: uuid.UUID
    conversation_id: uuid.UUID
    role: str
    content: str
    created_at: datetime

    model_config = {"from_attributes": True}


class AIConversationResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    created_at: datetime
    updated_at: datetime
    messages: list[AIMessageResponse] = []

    model_config = {"from_attributes": True}


class AIConversationSummary(BaseModel):
    id: uuid.UUID
    title: str
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class CreateConversationRequest(BaseModel):
    title: str = Field(default="New Conversation", max_length=200)


class SendMessageRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=4000)


class WeeklyReviewResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    week_start: str
    week_end: str
    content: str
    model_used: str
    created_at: datetime

    model_config = {"from_attributes": True}

    @classmethod
    def from_orm_obj(cls, obj: object) -> "WeeklyReviewResponse":
        return cls(
            id=obj.id,  # type: ignore[attr-defined]
            user_id=obj.user_id,  # type: ignore[attr-defined]
            week_start=str(obj.week_start),  # type: ignore[attr-defined]
            week_end=str(obj.week_end),  # type: ignore[attr-defined]
            content=obj.content,  # type: ignore[attr-defined]
            model_used=obj.model_used,  # type: ignore[attr-defined]
            created_at=obj.created_at,  # type: ignore[attr-defined]
        )
