"""weekly reviews table

Revision ID: 019
Revises: 018
Create Date: 2026-08-22
"""

from alembic import op
import sqlalchemy as sa

revision = "019"
down_revision = "018"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "weekly_reviews",
        sa.Column("id",          sa.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id",     sa.UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("week_start",  sa.Date, nullable=False),
        sa.Column("week_end",    sa.Date, nullable=False),
        sa.Column("content",     sa.Text, nullable=False),
        sa.Column("model_used",  sa.String(100), nullable=False),
        sa.Column("created_at",  sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_weekly_reviews_user_id", "weekly_reviews", ["user_id"])
    op.create_unique_constraint(
        "uq_weekly_reviews_user_week", "weekly_reviews", ["user_id", "week_start"]
    )


def downgrade() -> None:
    op.drop_table("weekly_reviews")
