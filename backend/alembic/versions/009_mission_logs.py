"""Mission logs table

Revision ID: 009
Revises: 008
Create Date: 2026-08-22
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "009"
down_revision: Union[str, None] = "008"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "mission_logs",
        sa.Column(
            "id",
            UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "mission_id",
            UUID(as_uuid=True),
            sa.ForeignKey("missions.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("evidence_text", sa.Text, nullable=False),
        sa.Column("reflection", sa.Text, nullable=True),
        sa.Column("effort_level", sa.Integer, nullable=False),
        sa.Column("xp_awarded", sa.Integer, nullable=False),
        sa.Column("streak_at_checkin", sa.Integer, nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.CheckConstraint(
            "effort_level >= 1 AND effort_level <= 5",
            name="ck_mission_logs_effort_level",
        ),
        sa.CheckConstraint("xp_awarded > 0", name="ck_mission_logs_xp_awarded_positive"),
        sa.CheckConstraint(
            "streak_at_checkin >= 1", name="ck_mission_logs_streak_positive"
        ),
    )
    op.create_index("ix_mission_logs_mission_id", "mission_logs", ["mission_id"])


def downgrade() -> None:
    op.drop_index("ix_mission_logs_mission_id", table_name="mission_logs")
    op.drop_table("mission_logs")
