"""
Pure functions for XP math, level progression, goal XP, and mission XP.

Level formula:   xp_for_level(n) = max(100, int(100 * n ** 1.8))
Rank thresholds: E 1-4  D 5-9  C 10-19  B 20-29  A 30-49  S 50+
Goal XP:         BASE_XP[difficulty] × EFFORT_MULTIPLIERS[effort_level]
Mission XP:      goal_xp × STREAK_MULTIPLIERS[streak_tier]
"""

_RANK_THRESHOLDS: list[tuple[int, str]] = [
    (50, "S"),
    (30, "A"),
    (20, "B"),
    (10, "C"),
    (5, "D"),
]

STAT_CATEGORIES: frozenset[str] = frozenset(
    {"vitality", "strength", "intelligence", "wisdom", "charisma", "discipline"}
)

GOAL_DIFFICULTIES: frozenset[str] = frozenset({"easy", "medium", "hard", "epic"})

_DIFFICULTY_BASE_XP: dict[str, int] = {
    "easy": 50,
    "medium": 100,
    "hard": 200,
    "epic": 500,
}

_EFFORT_MULTIPLIERS: dict[int, float] = {
    1: 0.5,
    2: 0.75,
    3: 1.0,
    4: 1.25,
    5: 1.5,
}


def xp_for_level(level: int) -> int:
    """XP required to advance FROM `level` TO `level + 1`."""
    return max(100, int(100 * level**1.8))


def rank_for_level(level: int) -> str:
    for threshold, rank in _RANK_THRESHOLDS:
        if level >= threshold:
            return rank
    return "E"


def apply_xp(
    current_level: int,
    current_level_xp: int,
    total_xp: int,
    amount: int,
) -> tuple[int, int, int, list[int]]:
    """
    Apply `amount` XP and compute the resulting character state.

    Returns (new_level, new_level_xp, new_total_xp, levels_gained).
    `levels_gained` lists each new level reached (empty when no level-up occurs).
    """
    new_total_xp = total_xp + amount
    level_xp = current_level_xp + amount
    level = current_level
    levels_gained: list[int] = []

    while level_xp >= xp_for_level(level):
        level_xp -= xp_for_level(level)
        level += 1
        levels_gained.append(level)

    return level, max(0, level_xp), new_total_xp, levels_gained


def calculate_goal_xp(difficulty: str, effort_level: int) -> int:
    """
    Deterministic XP for a completed goal.
    No randomness, no AI — formula is fully transparent to the user.
    """
    base = _DIFFICULTY_BASE_XP.get(difficulty, 100)
    multiplier = _EFFORT_MULTIPLIERS.get(effort_level, 1.0)
    return max(1, int(base * multiplier))


def get_streak_multiplier(streak: int) -> float:
    """XP multiplier based on consecutive-period completion streak."""
    if streak >= 30:
        return 2.0
    if streak >= 14:
        return 1.5
    if streak >= 7:
        return 1.25
    if streak >= 3:
        return 1.1
    return 1.0


def calculate_mission_xp(difficulty: str, effort_level: int, streak: int) -> int:
    """Deterministic XP for a mission check-in including streak bonus."""
    base = calculate_goal_xp(difficulty, effort_level)
    return max(1, int(base * get_streak_multiplier(streak)))
