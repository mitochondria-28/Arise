"""stat snapshots — daily character stat values for trend charts

Revision ID: 017
Revises: 016
Create Date: 2026-08-22
"""

from alembic import op
import sqlalchemy as sa

revision = "017"
down_revision = "016"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "stat_snapshots",
        sa.Column("id",           sa.UUID(as_uuid=True), primary_key=True),
        sa.Column("character_id", sa.UUID(as_uuid=True),
                  sa.ForeignKey("characters.id", ondelete="CASCADE"), nullable=False),
        sa.Column("snapshot_date",sa.Date, nullable=False),
        sa.Column("vitality",     sa.Integer, nullable=False, default=0),
        sa.Column("strength",     sa.Integer, nullable=False, default=0),
        sa.Column("intelligence", sa.Integer, nullable=False, default=0),
        sa.Column("wisdom",       sa.Integer, nullable=False, default=0),
        sa.Column("charisma",     sa.Integer, nullable=False, default=0),
        sa.Column("discipline",   sa.Integer, nullable=False, default=0),
        sa.Column("total_xp",     sa.Integer, nullable=False, default=0),
        sa.Column("level",        sa.Integer, nullable=False, default=1),
        sa.Column("created_at",   sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_stat_snapshots_character_id", "stat_snapshots", ["character_id"])
    op.create_unique_constraint(
        "uq_stat_snapshots_character_date", "stat_snapshots", ["character_id", "snapshot_date"]
    )


def downgrade() -> None:
    op.drop_table("stat_snapshots")
