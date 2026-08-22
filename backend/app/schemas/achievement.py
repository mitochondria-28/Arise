from pydantic import BaseModel


class AchievementResponse(BaseModel):
    key: str
    title: str
    description: str
    icon: str
    category: str
    threshold: int
    unlocked_at: str | None  # ISO-8601 or null


class SyncResponse(BaseModel):
    newly_unlocked: list[AchievementResponse]
    total_unlocked: int
