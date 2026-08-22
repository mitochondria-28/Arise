import pytest

from app.core.xp_engine import calculate_goal_xp


def test_easy_effort_1():
    assert calculate_goal_xp("easy", 1) == 25  # 50 * 0.5


def test_easy_effort_3():
    assert calculate_goal_xp("easy", 3) == 50  # 50 * 1.0


def test_easy_effort_5():
    assert calculate_goal_xp("easy", 5) == 75  # 50 * 1.5


def test_medium_effort_3():
    assert calculate_goal_xp("medium", 3) == 100  # 100 * 1.0


def test_medium_effort_1():
    assert calculate_goal_xp("medium", 1) == 50  # 100 * 0.5


def test_hard_effort_3():
    assert calculate_goal_xp("hard", 3) == 200  # 200 * 1.0


def test_hard_effort_5():
    assert calculate_goal_xp("hard", 5) == 300  # 200 * 1.5


def test_epic_effort_3():
    assert calculate_goal_xp("epic", 3) == 500  # 500 * 1.0


def test_epic_effort_5():
    assert calculate_goal_xp("epic", 5) == 750  # 500 * 1.5


def test_epic_effort_1():
    assert calculate_goal_xp("epic", 1) == 250  # 500 * 0.5


def test_minimum_xp_is_1():
    # Even lowest difficulty × lowest effort cannot produce 0
    result = calculate_goal_xp("easy", 1)
    assert result >= 1


def test_higher_effort_yields_more_xp():
    for diff in ("easy", "medium", "hard", "epic"):
        for effort in range(1, 5):
            assert calculate_goal_xp(diff, effort) < calculate_goal_xp(diff, effort + 1)


def test_higher_difficulty_yields_more_xp():
    for effort in range(1, 6):
        assert calculate_goal_xp("easy", effort) < calculate_goal_xp("medium", effort)
        assert calculate_goal_xp("medium", effort) < calculate_goal_xp("hard", effort)
        assert calculate_goal_xp("hard", effort) < calculate_goal_xp("epic", effort)
