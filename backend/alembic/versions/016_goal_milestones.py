"""goal milestones — sub-tasks within a goal

Revision ID: 016
Revises: 015
Create Date: 2026-08-22
"""

from alembic import op
import sqlalchemy as sa

revision = "016"
down_revision = "015"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "goal_milestones",
        sa.Column("id",           sa.UUID(as_uuid=True), primary_key=True),
        sa.Column("goal_id",      sa.UUID(as_uuid=True),
                  sa.ForeignKey("goals.id", ondelete="CASCADE"), nullable=False),
        sa.Column("title",        sa.String(200), nullable=False),
        sa.Column("description",  sa.Text, nullable=True),
        sa.Column("is_completed", sa.Boolean, nullable=False, default=False),
        sa.Column("sort_order",   sa.Integer, nullable=False, default=0),
        sa.Column("created_at",   sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at",   sa.DateTime(timezone=True),
                  server_default=sa.func.now(), onupdate=sa.func.now(), nullable=False),
    )
    op.create_index("ix_goal_milestones_goal_id", "goal_milestones", ["goal_id"])


def downgrade() -> None:
    op.drop_table("goal_milestones")
