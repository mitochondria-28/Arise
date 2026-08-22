from dataclasses import dataclass

RANK_ORDER = {"E": 0, "D": 1, "C": 2, "B": 3, "A": 4, "S": 5}


@dataclass(frozen=True)
class AchievementDef:
    key: str
    title: str
    description: str
    icon: str
    # category drives which metric is checked against threshold
    # "xp" → total_xp, "goals" → goals_completed, "streak" → best_streak,
    # "missions" → total_checkins, "level" → character.level,
    # "rank" → RANK_ORDER[character.rank] >= threshold (1=D … 5=S)
    category: str
    threshold: int


ACHIEVEMENTS: list[AchievementDef] = [
    # ── XP ────────────────────────────────────────────────────────────────────
    AchievementDef("xp_100",   "First Spark",    "Earn 100 XP",        "⚡", "xp",      100),
    AchievementDef("xp_500",   "Rising Hunter",  "Earn 500 XP",        "🌟", "xp",      500),
    AchievementDef("xp_1000",  "Warrior",        "Earn 1,000 XP",      "⚔️", "xp",    1_000),
    AchievementDef("xp_5000",  "Champion",       "Earn 5,000 XP",      "🏆", "xp",    5_000),
    AchievementDef("xp_10000", "Legend",         "Earn 10,000 XP",     "👑", "xp",   10_000),
    # ── Goals ─────────────────────────────────────────────────────────────────
    AchievementDef("goals_1",  "First Step",     "Complete 1 goal",    "🎯", "goals",    1),
    AchievementDef("goals_5",  "Goal Seeker",    "Complete 5 goals",   "🎯", "goals",    5),
    AchievementDef("goals_10", "Goal Crusher",   "Complete 10 goals",  "💪", "goals",   10),
    AchievementDef("goals_25", "Achiever",       "Complete 25 goals",  "🚀", "goals",   25),
    AchievementDef("goals_50", "Centurion",      "Complete 50 goals",  "🏅", "goals",   50),
    # ── Streak ────────────────────────────────────────────────────────────────
    AchievementDef("streak_3",   "On a Roll",    "Reach a 3-day streak",   "🔥", "streak",   3),
    AchievementDef("streak_7",   "Week Warrior", "Reach a 7-day streak",   "🔥", "streak",   7),
    AchievementDef("streak_14",  "Iron Will",    "Reach a 14-day streak",  "💎", "streak",  14),
    AchievementDef("streak_30",  "Unstoppable",  "Reach a 30-day streak",  "🌊", "streak",  30),
    AchievementDef("streak_100", "Legendary",    "Reach a 100-day streak", "👑", "streak", 100),
    # ── Mission check-ins ─────────────────────────────────────────────────────
    AchievementDef("checkins_10",  "Dedicated",  "Complete 10 check-ins",  "✅", "missions",  10),
    AchievementDef("checkins_50",  "Consistent", "Complete 50 check-ins",  "🏅", "missions",  50),
    AchievementDef("checkins_100", "Machine",    "Complete 100 check-ins", "🤖", "missions", 100),
    # ── Level ─────────────────────────────────────────────────────────────────
    AchievementDef("level_5",  "Ascending",      "Reach Level 5",  "📈", "level",  5),
    AchievementDef("level_10", "Veteran",        "Reach Level 10", "🛡️", "level", 10),
    AchievementDef("level_20", "Elite",          "Reach Level 20", "⭐", "level", 20),
    AchievementDef("level_50", "Shadow Monarch", "Reach Level 50", "👑", "level", 50),
    # ── Rank ──────────────────────────────────────────────────────────────────
    AchievementDef("rank_D", "Rank D Achieved", "Reach Rank D", "🟢", "rank", 1),
    AchievementDef("rank_C", "Rank C Achieved", "Reach Rank C", "🔵", "rank", 2),
    AchievementDef("rank_B", "Rank B Achieved", "Reach Rank B", "🟣", "rank", 3),
    AchievementDef("rank_A", "Rank A Achieved", "Reach Rank A", "🟠", "rank", 4),
    AchievementDef("rank_S", "Shadow Monarch",  "Reach Rank S", "🔴", "rank", 5),
]

ACHIEVEMENT_MAP: dict[str, AchievementDef] = {a.key: a for a in ACHIEVEMENTS}


def qualifies(
    ach: AchievementDef,
    *,
    total_xp: int,
    goals_completed: int,
    best_streak: int,
    total_checkins: int,
    level: int,
    rank: str,
) -> bool:
    cat = ach.category
    if cat == "xp":       return total_xp >= ach.threshold
    if cat == "goals":    return goals_completed >= ach.threshold
    if cat == "streak":   return best_streak >= ach.threshold
    if cat == "missions": return total_checkins >= ach.threshold
    if cat == "level":    return level >= ach.threshold
    if cat == "rank":     return RANK_ORDER.get(rank, 0) >= ach.threshold
    return False
