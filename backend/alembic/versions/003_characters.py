"""Characters table

Revision ID: 003
Revises: 002
Create Date: 2026-08-22
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "003"
down_revision: Union[str, None] = "002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "characters",
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
            unique=True,
            nullable=False,
        ),
        sa.Column("title", sa.String(100), nullable=False, server_default="The Awakened"),
        sa.Column("level", sa.Integer, nullable=False, server_default="1"),
        sa.Column("total_xp", sa.Integer, nullable=False, server_default="0"),
        sa.Column("current_level_xp", sa.Integer, nullable=False, server_default="0"),
        sa.Column("rank", sa.String(5), nullable=False, server_default="E"),
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
    op.create_index("ix_characters_user_id", "characters", ["user_id"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_characters_user_id", table_name="characters")
    op.drop_table("characters")
