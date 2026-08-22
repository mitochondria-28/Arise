"""Goals table

Revision ID: 006
Revises: 005
Create Date: 2026-08-22
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "006"
down_revision: Union[str, None] = "005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_STATUS_CHECK = "status IN ('active', 'completed', 'abandoned', 'archived')"
_DIFFICULTY_CHECK = "difficulty IN ('easy', 'medium', 'hard', 'epic')"
_CATEGORY_CHECK = (
    "category IN ('vitality', 'strength', 'intelligence', 'wisdom', 'charisma', 'discipline')"
)


def upgrade() -> None:
    op.create_table(
        "goals",
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
        sa.Column("target_date", sa.Date, nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="active"),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
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
        sa.CheckConstraint(_STATUS_CHECK, name="ck_goals_status"),
        sa.CheckConstraint(_DIFFICULTY_CHECK, name="ck_goals_difficulty"),
        sa.CheckConstraint(_CATEGORY_CHECK, name="ck_goals_category"),
    )
    op.create_index("ix_goals_user_id", "goals", ["user_id"])
    op.create_index("ix_goals_status", "goals", ["status"])
    op.create_index("ix_goals_category", "goals", ["category"])


def downgrade() -> None:
    op.drop_index("ix_goals_category", table_name="goals")
    op.drop_index("ix_goals_status", table_name="goals")
    op.drop_index("ix_goals_user_id", table_name="goals")
    op.drop_table("goals")
