from pydantic import BaseModel


class MissionStreakEntry(BaseModel):
    title: str
    current_streak: int
    longest_streak: int
    completion_count: int
    frequency: str


class StatsSummaryResponse(BaseModel):
    total_xp: int
    current_level: int
    rank: str
    goals_completed: int
    goals_by_difficulty: dict[str, int]
    goals_by_category: dict[str, int]
    missions_active: int
    total_checkins: int
    best_streak: int
    current_streak_max: int
    top_missions: list[MissionStreakEntry]


class XPDayEntry(BaseModel):
    date: str  # ISO date "YYYY-MM-DD"
    xp: int
    goal_xp: int
    mission_xp: int


class XPHistoryResponse(BaseModel):
    entries: list[XPDayEntry]
    total_xp_in_period: int
    days: int


class StatHistoryEntry(BaseModel):
    date: str  # ISO "YYYY-MM-DD"
    vitality: int
    strength: int
    intelligence: int
    wisdom: int
    charisma: int
    discipline: int
    total_xp: int
    level: int


class StatHistoryResponse(BaseModel):
    entries: list[StatHistoryEntry]
    days: int
