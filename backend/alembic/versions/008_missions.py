"""Missions table

Revision ID: 008
Revises: 007
Create Date: 2026-08-22
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "008"
down_revision: Union[str, None] = "007"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_STATUS_CHECK = "status IN ('active', 'paused', 'completed', 'archived')"
_DIFFICULTY_CHECK = "difficulty IN ('easy', 'medium', 'hard', 'epic')"
_FREQUENCY_CHECK = "frequency IN ('daily', 'weekly', 'monthly')"
_CATEGORY_CHECK = (
    "category IN ('vitality', 'strength', 'intelligence', 'wisdom', 'charisma', 'discipline')"
)


def upgrade() -> None:
    op.create_table(
        "missions",
        sa.Column(
            "id",
            UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "user_id",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("category", sa.String(50), nullable=False),
        sa.Column("difficulty", sa.String(20), nullable=False),
        sa.Column("frequency", sa.String(20), nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="active"),
        sa.Column("target_count", sa.Integer, nullable=False, server_default="0"),
        sa.Column("completion_count", sa.Integer, nullable=False, server_default="0"),
        sa.Column("current_streak", sa.Integer, nullable=False, server_default="0"),
        sa.Column("longest_streak", sa.Integer, nullable=False, server_default="0"),
        sa.Column("last_completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.CheckConstraint(_STATUS_CHECK, name="ck_missions_status"),
        sa.CheckConstraint(_DIFFICULTY_CHECK, name="ck_missions_difficulty"),
        sa.CheckConstraint(_FREQUENCY_CHECK, name="ck_missions_frequency"),
        sa.CheckConstraint(_CATEGORY_CHECK, name="ck_missions_category"),
        sa.CheckConstraint("target_count >= 0", name="ck_missions_target_count"),
        sa.CheckConstraint("completion_count >= 0", name="ck_missions_completion_count"),
        sa.CheckConstraint("current_streak >= 0", name="ck_missions_current_streak"),
    )
    op.create_index("ix_missions_user_id", "missions", ["user_id"])
    op.create_index("ix_missions_status", "missions", ["status"])
    op.create_index("ix_missions_frequency", "missions", ["frequency"])


def downgrade() -> None:
    op.drop_index("ix_missions_frequency", table_name="missions")
    op.drop_index("ix_missions_status", table_name="missions")
    op.drop_index("ix_missions_user_id", table_name="missions")
    op.drop_table("missions")
