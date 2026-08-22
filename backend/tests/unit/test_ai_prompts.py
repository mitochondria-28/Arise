"""
Unit tests for Gemini prompt builders.
These are pure string functions — no API calls, no DB, no mocks needed.
"""
from app.core.gemini import gemini_client


def test_goal_prompt_contains_core_fields():
    prompt = gemini_client.build_goal_prompt(
        display_name="Sung Jinwoo",
        goal_title="Read 12 books on cognitive science",
        goal_category="intelligence",
        goal_difficulty="hard",
        evidence_text="Finished all 12 books and kept detailed notes in Obsidian.",
        reflection="My reading speed improved by ~30%.",
        effort_level=4,
        xp_awarded=250,
    )
    assert "Sung Jinwoo" in prompt
    assert "Read 12 books on cognitive science" in prompt
    assert "intelligence" in prompt
    assert "hard" in prompt
    assert "Finished all 12 books" in prompt
    assert "reading speed" in prompt
    assert "4/5" in prompt
    assert "250" in prompt


def test_goal_prompt_no_reflection_uses_fallback():
    prompt = gemini_client.build_goal_prompt(
        display_name="Hunter",
        goal_title="Run a 5K",
        goal_category="vitality",
        goal_difficulty="easy",
        evidence_text="Completed 5K in 28 minutes.",
        reflection=None,
        effort_level=3,
        xp_awarded=50,
    )
    assert "Not provided" in prompt


def test_mission_prompt_contains_streak_when_high():
    prompt = gemini_client.build_mission_prompt(
        display_name="Hunter",
        mission_title="Daily meditation",
        mission_category="wisdom",
        mission_frequency="daily",
        current_streak=10,
        evidence_text="Meditated for 20 minutes using Waking Up app.",
        reflection=None,
        effort_level=2,
        xp_awarded=75,
    )
    assert "Daily meditation" in prompt
    assert "streak: 10" in prompt
    assert "daily" in prompt
    assert "wisdom" in prompt


def test_mission_prompt_omits_streak_when_low():
    prompt = gemini_client.build_mission_prompt(
        display_name="Hunter",
        mission_title="Push-ups",
        mission_category="strength",
        mission_frequency="daily",
        current_streak=2,
        evidence_text="Did 50 push-ups before breakfast.",
        reflection=None,
        effort_level=3,
        xp_awarded=100,
    )
    assert "streak:" not in prompt


def test_growth_report_prompt_includes_stats_and_completions():
    prompt = gemini_client.build_growth_report_prompt(
        display_name="Jinwoo",
        level=15,
        rank="C",
        total_xp=3200,
        stats={"vitality": 12, "strength": 8, "intelligence": 5, "wisdom": 3, "charisma": 1, "discipline": 9},
        recent_completions=["Read 12 books", "Run a marathon"],
        top_missions=["Daily push-ups (streak: 21)"],
    )
    assert "Jinwoo" in prompt
    assert "Level 15" in prompt
    assert "C-rank" in prompt
    assert "3200" in prompt
    assert "vitality: 12" in prompt
    assert "Read 12 books" in prompt
    assert "Daily push-ups" in prompt


def test_growth_report_prompt_handles_no_completions():
    prompt = gemini_client.build_growth_report_prompt(
        display_name="New Hunter",
        level=1,
        rank="E",
        total_xp=0,
        stats={},
        recent_completions=[],
        top_missions=[],
    )
    assert "None yet" in prompt
    assert "None active" in prompt
    assert "all at 0" in prompt


def test_growth_report_prompt_caps_at_5_completions():
    completions = [f"Goal {i}" for i in range(10)]
    prompt = gemini_client.build_growth_report_prompt(
        display_name="Hunter",
        level=5,
        rank="D",
        total_xp=500,
        stats={"vitality": 1},
        recent_completions=completions,
        top_missions=[],
    )
    assert "Goal 4" in prompt
    assert "Goal 5" not in prompt
