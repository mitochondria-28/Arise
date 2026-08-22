import uuid

from sqlalchemy import Boolean, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base, TimestampMixin, UUIDMixin


class GoalMilestone(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "goal_milestones"

    goal_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("goals.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_completed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    goal: Mapped["Goal"] = relationship("Goal", back_populates="milestones")  # type: ignore[name-defined]

    def __repr__(self) -> str:
        return f"<GoalMilestone id={self.id} title={self.title!r} done={self.is_completed}>"
