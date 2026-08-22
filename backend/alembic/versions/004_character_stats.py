"""Character stats table

Revision ID: 004
Revises: 003
Create Date: 2026-08-22
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "004"
down_revision: Union[str, None] = "003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "character_stats",
        sa.Column(
            "id",
            UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "character_id",
            UUID(as_uuid=True),
            sa.ForeignKey("characters.id", ondelete="CASCADE"),
            unique=True,
            nullable=False,
        ),
        sa.Column("vitality", sa.Integer, nullable=False, server_default="0"),
        sa.Column("strength", sa.Integer, nullable=False, server_default="0"),
        sa.Column("intelligence", sa.Integer, nullable=False, server_default="0"),
        sa.Column("wisdom", sa.Integer, nullable=False, server_default="0"),
        sa.Column("charisma", sa.Integer, nullable=False, server_default="0"),
        sa.Column("discipline", sa.Integer, nullable=False, server_default="0"),
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
    )
    op.create_index(
        "ix_character_stats_character_id", "character_stats", ["character_id"], unique=True
    )


def downgrade() -> None:
    op.drop_index("ix_character_stats_character_id", table_name="character_stats")
    op.drop_table("character_stats")
