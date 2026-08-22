"""Journal entries table

Revision ID: 012
Revises: 011
Create Date: 2026-08-22
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "012"
down_revision: Union[str, None] = "011"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "journal_entries",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("entry_date", sa.Date, nullable=False),
        sa.Column("content", sa.Text, nullable=False),
        sa.Column("mood", sa.Integer, nullable=True),
        sa.Column("ai_reflection", sa.Text, nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.UniqueConstraint("user_id", "entry_date", name="uq_user_journal_date"),
    )
    op.create_index(
        "ix_journal_entries_user_id",
        "journal_entries",
        ["user_id"],
    )
    op.create_index(
        "ix_journal_entries_user_date",
        "journal_entries",
        ["user_id", "entry_date"],
    )


def downgrade() -> None:
    op.drop_index("ix_journal_entries_user_date", table_name="journal_entries")
    op.drop_index("ix_journal_entries_user_id", table_name="journal_entries")
    op.drop_table("journal_entries")
