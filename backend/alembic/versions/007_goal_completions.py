"""Goal completions table

Revision ID: 007
Revises: 006
Create Date: 2026-08-22
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "007"
down_revision: Union[str, None] = "006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "goal_completions",
        sa.Column(
            "id",
            UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "goal_id",
            UUID(as_uuid=True),
            sa.ForeignKey("goals.id", ondelete="CASCADE"),
            unique=True,
            nullable=False,
        ),
        sa.Column("evidence_text", sa.Text, nullable=False),
        sa.Column("reflection", sa.Text, nullable=True),
        sa.Column("effort_level", sa.Integer, nullable=False),
        sa.Column("xp_awarded", sa.Integer, nullable=False),
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
        sa.CheckConstraint(
            "effort_level >= 1 AND effort_level <= 5", name="ck_goal_completions_effort_level"
        ),
        sa.CheckConstraint("xp_awarded > 0", name="ck_goal_completions_xp_awarded_positive"),
    )
    op.create_index("ix_goal_completions_goal_id", "goal_completions", ["goal_id"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_goal_completions_goal_id", table_name="goal_completions")
    op.drop_table("goal_completions")
