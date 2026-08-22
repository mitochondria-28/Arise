import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class AIAnalysisResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    character_id: uuid.UUID
    source_type: str
    source_id: uuid.UUID | None
    content: str
    model_used: str
    created_at: datetime
