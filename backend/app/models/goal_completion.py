import uuid

from sqlalchemy import ForeignKey, Integer, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base, TimestampMixin, UUIDMixin


class GoalCompletion(UUIDMixin, TimestampMixin, Base):
    """
    Evidence record written when a goal is completed.
    Never updated — it is the permanent proof of completion.
    """

    __tablename__ = "goal_completions"

    goal_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("goals.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )
    evidence_text: Mapped[str] = mapped_column(Text, nullable=False)
    reflection: Mapped[str | None] = mapped_column(Text, nullable=True)
    # 1 (minimal) → 5 (maximum effort)
    effort_level: Mapped[int] = mapped_column(Integer, nullable=False)
    xp_awarded: Mapped[int] = mapped_column(Integer, nullable=False)

    goal: Mapped["Goal"] = relationship("Goal", back_populates="completion")  # type: ignore[name-defined]

    def __repr__(self) -> str:
        return (
            f"<GoalCompletion goal_id={self.goal_id}"
            f" effort={self.effort_level} xp={self.xp_awarded}>"
        )
