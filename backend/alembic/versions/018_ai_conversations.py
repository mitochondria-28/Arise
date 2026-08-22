"""ai conversations and messages tables

Revision ID: 018
Revises: 017
Create Date: 2026-08-22
"""

from alembic import op
import sqlalchemy as sa

revision = "018"
down_revision = "017"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "ai_conversations",
        sa.Column("id",         sa.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id",    sa.UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("title",      sa.String(200), nullable=False, server_default="New Conversation"),
        sa.Column("created_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), onupdate=sa.func.now(), nullable=False),
    )
    op.create_index("ix_ai_conversations_user_id", "ai_conversations", ["user_id"])

    op.create_table(
        "ai_messages",
        sa.Column("id",              sa.UUID(as_uuid=True), primary_key=True),
        sa.Column("conversation_id", sa.UUID(as_uuid=True),
                  sa.ForeignKey("ai_conversations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("role",    sa.String(10), nullable=False),   # "user" | "model"
        sa.Column("content", sa.Text,       nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_ai_messages_conversation_id", "ai_messages", ["conversation_id"])


def downgrade() -> None:
    op.drop_table("ai_messages")
    op.drop_table("ai_conversations")
