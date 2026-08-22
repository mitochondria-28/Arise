"""AI analyses table

Revision ID: 010
Revises: 009
Create Date: 2026-08-22
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "010"
down_revision: Union[str, None] = "009"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "ai_analyses",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "character_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("characters.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("source_type", sa.String(50), nullable=False),
        sa.Column("source_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("prompt", sa.Text, nullable=False),
        sa.Column("content", sa.Text, nullable=False),
        sa.Column("model_used", sa.String(100), nullable=False),
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
            "source_type IN ('goal', 'mission', 'growth_report')",
            name="ck_ai_analyses_source_type",
        ),
    )
    op.create_index("ix_ai_analyses_character_id", "ai_analyses", ["character_id"])
    op.create_index("ix_ai_analyses_source_id", "ai_analyses", ["source_id"])
    op.create_index(
        "ix_ai_analyses_source_lookup",
        "ai_analyses",
        ["source_type", "source_id", "created_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_ai_analyses_source_lookup", table_name="ai_analyses")
    op.drop_index("ix_ai_analyses_source_id", table_name="ai_analyses")
    op.drop_index("ix_ai_analyses_character_id", table_name="ai_analyses")
    op.drop_table("ai_analyses")
