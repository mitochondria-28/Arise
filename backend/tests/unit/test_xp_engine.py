import pytest

from app.core.xp_engine import apply_xp, rank_for_level, xp_for_level


# ── xp_for_level ──────────────────────────────────────────────────────────────

def test_xp_for_level_1_is_100():
    assert xp_for_level(1) == 100


def test_xp_for_level_2_is_greater_than_1():
    assert xp_for_level(2) > xp_for_level(1)


def test_xp_for_level_increases_monotonically():
    for lvl in range(1, 20):
        assert xp_for_level(lvl) < xp_for_level(lvl + 1)


# ── rank_for_level ─────────────────────────────────────────────────────────────

def test_rank_e_levels_1_to_4():
    for lvl in range(1, 5):
        assert rank_for_level(lvl) == "E", f"level {lvl} should be E"


def test_rank_d_at_level_5():
    assert rank_for_level(5) == "D"


def test_rank_d_at_level_9():
    assert rank_for_level(9) == "D"


def test_rank_c_at_level_10():
    assert rank_for_level(10) == "C"


def test_rank_b_at_level_20():
    assert rank_for_level(20) == "B"


def test_rank_a_at_level_30():
    assert rank_for_level(30) == "A"


def test_rank_s_at_level_50():
    assert rank_for_level(50) == "S"


def test_rank_s_at_level_100():
    assert rank_for_level(100) == "S"


# ── apply_xp ──────────────────────────────────────────────────────────────────

def test_apply_xp_no_levelup():
    level, lvl_xp, total, gained = apply_xp(1, 0, 0, 50)
    assert level == 1
    assert lvl_xp == 50
    assert total == 50
    assert gained == []


def test_apply_xp_zero_amount_is_noop():
    level, lvl_xp, total, gained = apply_xp(1, 50, 50, 0)
    assert level == 1
    assert lvl_xp == 50
    assert total == 50
    assert gained == []


def test_apply_xp_exact_single_levelup():
    # Level 1 requires exactly 100 XP
    level, lvl_xp, total, gained = apply_xp(1, 0, 0, 100)
    assert level == 2
    assert lvl_xp == 0
    assert total == 100
    assert gained == [2]


def test_apply_xp_overflow_carries_into_next_level():
    # 150 XP: 100 used for L1→L2, 50 left in L2
    level, lvl_xp, total, gained = apply_xp(1, 0, 0, 150)
    assert level == 2
    assert lvl_xp == 50
    assert total == 150
    assert gained == [2]


def test_apply_xp_multi_levelup():
    level, lvl_xp, total, gained = apply_xp(1, 0, 0, 10_000)
    assert level > 3
    assert len(gained) > 1
    assert total == 10_000


def test_apply_xp_accumulates_total():
    _, _, total1, _ = apply_xp(1, 0, 0, 50)
    _, _, total2, _ = apply_xp(1, 50, total1, 50)
    assert total2 == 100


def test_apply_xp_level_xp_never_negative():
    _, lvl_xp, _, _ = apply_xp(1, 0, 0, 0)
    assert lvl_xp >= 0
