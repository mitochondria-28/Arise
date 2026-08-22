import uuid
from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base, TimestampMixin, UUIDMixin


class Goal(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "goals"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    # One of STAT_CATEGORIES
    category: Mapped[str] = mapped_column(String(50), nullable=False)
    # "easy" | "medium" | "hard" | "epic"
    difficulty: Mapped[str] = mapped_column(String(20), nullable=False)
    target_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    # "active" | "completed" | "abandoned" | "archived"
    status: Mapped[str] = mapped_column(String(20), default="active", nullable=False)
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    user: Mapped["User"] = relationship("User", back_populates="goals")  # type: ignore[name-defined]
    completion: Mapped["GoalCompletion"] = relationship(  # type: ignore[name-defined]
        "GoalCompletion",
        back_populates="goal",
        uselist=False,
        cascade="all, delete-orphan",
    )
    milestones: Mapped[list["GoalMilestone"]] = relationship(  # type: ignore[name-defined]
        "GoalMilestone",
        back_populates="goal",
        cascade="all, delete-orphan",
        order_by="GoalMilestone.sort_order",
    )

    def __repr__(self) -> str:
        return f"<Goal id={self.id} title={self.title!r} status={self.status!r}>"
