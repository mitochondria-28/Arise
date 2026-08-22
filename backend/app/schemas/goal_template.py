import uuid
from pydantic import BaseModel, ConfigDict


class GoalTemplateResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    description: str
    category: str
    difficulty: str
    emoji: str
    sort_order: int
