"""
Period and streak utilities for the mission system.

All functions accept an optional `now` parameter for deterministic testing;
production callers omit it and get the real UTC time.
"""
from datetime import date, datetime, timezone

MISSION_FREQUENCIES: frozenset[str] = frozenset({"daily", "weekly", "monthly"})


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _to_utc_date(dt: datetime) -> date:
    if dt.tzinfo is None:
        return dt.date()
    return dt.astimezone(timezone.utc).date()


def is_same_period(
    last_completed_at: datetime,
    frequency: str,
    *,
    now: datetime | None = None,
) -> bool:
    """True when last_completed_at falls in the same period as now (already checked in)."""
    today = _to_utc_date(now or _utc_now())
    last = _to_utc_date(last_completed_at)

    if frequency == "daily":
        return last == today
    if frequency == "weekly":
        return last.isocalendar()[:2] == today.isocalendar()[:2]
    if frequency == "monthly":
        return (last.year, last.month) == (today.year, today.month)
    return False


def is_streak_maintained(
    last_completed_at: datetime,
    frequency: str,
    *,
    now: datetime | None = None,
) -> bool:
    """True when last_completed_at is exactly one period before now (streak continues)."""
    today = _to_utc_date(now or _utc_now())
    last = _to_utc_date(last_completed_at)

    if frequency == "daily":
        return (today - last).days == 1

    if frequency == "weekly":
        t_year, t_week, _ = today.isocalendar()
        l_year, l_week, _ = last.isocalendar()
        if t_year == l_year:
            return t_week - l_week == 1
        # Cross-year: last week of previous year → week 1 of new year
        if t_year == l_year + 1 and t_week == 1:
            return l_week == date(l_year, 12, 28).isocalendar()[1]
        return False

    if frequency == "monthly":
        if today.year == last.year:
            return today.month - last.month == 1
        if today.year == last.year + 1 and today.month == 1:
            return last.month == 12
        return False

    return False
