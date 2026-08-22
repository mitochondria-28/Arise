"""
Unit tests for streak/period utilities and mission XP calculation.
All time-sensitive functions accept an explicit `now` kwarg for determinism.
"""
from datetime import date, datetime, timedelta, timezone

import pytest

from app.core.mission_engine import is_same_period, is_streak_maintained
from app.core.xp_engine import calculate_mission_xp, get_streak_multiplier


def _dt(d: date) -> datetime:
    """Convert a date to a UTC midnight datetime."""
    return datetime(d.year, d.month, d.day, tzinfo=timezone.utc)


TODAY = date(2026, 8, 22)
NOW = _dt(TODAY)
YESTERDAY = _dt(TODAY - timedelta(days=1))
TWO_DAYS_AGO = _dt(TODAY - timedelta(days=2))


# ── get_streak_multiplier ──────────────────────────────────────────────────────

def test_streak_1_no_bonus():
    assert get_streak_multiplier(1) == 1.0


def test_streak_2_no_bonus():
    assert get_streak_multiplier(2) == 1.0


def test_streak_3_small_bonus():
    assert get_streak_multiplier(3) == 1.1


def test_streak_6_small_bonus():
    assert get_streak_multiplier(6) == 1.1


def test_streak_7_medium_bonus():
    assert get_streak_multiplier(7) == 1.25


def test_streak_13_medium_bonus():
    assert get_streak_multiplier(13) == 1.25


def test_streak_14_large_bonus():
    assert get_streak_multiplier(14) == 1.5


def test_streak_29_large_bonus():
    assert get_streak_multiplier(29) == 1.5


def test_streak_30_double():
    assert get_streak_multiplier(30) == 2.0


def test_streak_100_double():
    assert get_streak_multiplier(100) == 2.0


# ── calculate_mission_xp ──────────────────────────────────────────────────────

def test_mission_xp_no_streak_bonus():
    # medium + effort 3 = 100 base, streak 1 = 1.0x
    assert calculate_mission_xp("medium", 3, 1) == 100


def test_mission_xp_with_streak_3_bonus():
    # medium + effort 3 = 100, streak 3 = 1.1x → 110
    assert calculate_mission_xp("medium", 3, 3) == 110


def test_mission_xp_with_streak_7_bonus():
    # hard + effort 3 = 200, streak 7 = 1.25x → 250
    assert calculate_mission_xp("hard", 3, 7) == 250


def test_mission_xp_with_streak_30_double():
    # easy + effort 3 = 50, streak 30 = 2.0x → 100
    assert calculate_mission_xp("easy", 3, 30) == 100


# ── is_same_period (daily) ────────────────────────────────────────────────────

def test_daily_same_day_is_same_period():
    assert is_same_period(NOW, "daily", now=NOW) is True


def test_daily_yesterday_not_same_period():
    assert is_same_period(YESTERDAY, "daily", now=NOW) is False


def test_daily_two_days_ago_not_same_period():
    assert is_same_period(TWO_DAYS_AGO, "daily", now=NOW) is False


# ── is_same_period (weekly) ───────────────────────────────────────────────────

def test_weekly_same_week_is_same_period():
    # 2026-08-22 is Saturday; Monday of same week is 2026-08-17
    same_week = _dt(date(2026, 8, 17))
    assert is_same_period(same_week, "weekly", now=NOW) is True


def test_weekly_last_week_not_same_period():
    last_week = _dt(date(2026, 8, 10))  # week before
    assert is_same_period(last_week, "weekly", now=NOW) is False


# ── is_same_period (monthly) ──────────────────────────────────────────────────

def test_monthly_same_month_is_same_period():
    same_month = _dt(date(2026, 8, 1))
    assert is_same_period(same_month, "monthly", now=NOW) is True


def test_monthly_last_month_not_same_period():
    last_month = _dt(date(2026, 7, 31))
    assert is_same_period(last_month, "monthly", now=NOW) is False


# ── is_streak_maintained (daily) ─────────────────────────────────────────────

def test_daily_yesterday_maintains_streak():
    assert is_streak_maintained(YESTERDAY, "daily", now=NOW) is True


def test_daily_today_does_not_maintain_streak():
    assert is_streak_maintained(NOW, "daily", now=NOW) is False


def test_daily_two_days_ago_breaks_streak():
    assert is_streak_maintained(TWO_DAYS_AGO, "daily", now=NOW) is False


# ── is_streak_maintained (weekly) ────────────────────────────────────────────

def test_weekly_previous_week_maintains_streak():
    # NOW is 2026-08-22 (week 34). Previous week: 2026-08-10 (week 33)
    prev_week = _dt(date(2026, 8, 10))
    assert is_streak_maintained(prev_week, "weekly", now=NOW) is True


def test_weekly_two_weeks_ago_breaks_streak():
    two_weeks_ago = _dt(date(2026, 8, 3))  # week 32
    assert is_streak_maintained(two_weeks_ago, "weekly", now=NOW) is False


# ── is_streak_maintained (monthly) ───────────────────────────────────────────

def test_monthly_previous_month_maintains_streak():
    prev_month = _dt(date(2026, 7, 15))
    assert is_streak_maintained(prev_month, "monthly", now=NOW) is True


def test_monthly_two_months_ago_breaks_streak():
    two_months = _dt(date(2026, 6, 15))
    assert is_streak_maintained(two_months, "monthly", now=NOW) is False


def test_monthly_cross_year_maintains_streak():
    # NOW in January 2027, last in December 2026
    jan_now = _dt(date(2027, 1, 15))
    dec_last = _dt(date(2026, 12, 15))
    assert is_streak_maintained(dec_last, "monthly", now=jan_now) is True
