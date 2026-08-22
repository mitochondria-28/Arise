"""XP transactions table

Revision ID: 005
Revises: 004
Create Date: 2026-08-22
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB, UUID

revision: str = "005"
down_revision: Union[str, None] = "004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "xp_transactions",
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
            nullable=False,
        ),
        sa.Column("amount", sa.Integer, nullable=False),
        sa.Column("source_type", sa.String(50), nullable=False),
        sa.Column("source_id", UUID(as_uuid=True), nullable=True),
        sa.Column("stat_category", sa.String(50), nullable=True),
        sa.Column("description", sa.Text, nullable=False),
        sa.Column("metadata", JSONB, nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index("ix_xp_transactions_character_id", "xp_transactions", ["character_id"])
    op.create_index("ix_xp_transactions_source_type", "xp_transactions", ["source_type"])


def downgrade() -> None:
    op.drop_index("ix_xp_transactions_source_type", table_name="xp_transactions")
    op.drop_index("ix_xp_transactions_character_id", table_name="xp_transactions")
    op.drop_table("xp_transactions")
