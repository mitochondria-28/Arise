import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base, TimestampMixin, UUIDMixin


class Mission(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "missions"

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
    # "daily" | "weekly" | "monthly"
    frequency: Mapped[str] = mapped_column(String(20), nullable=False)
    # "active" | "paused" | "completed" | "archived"
    status: Mapped[str] = mapped_column(String(20), default="active", nullable=False)
    # 0 = unlimited; >0 = auto-complete when completion_count reaches this
    target_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    completion_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    current_streak: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    longest_streak: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    last_completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    user: Mapped["User"] = relationship("User", back_populates="missions")  # type: ignore[name-defined]
    logs: Mapped[list["MissionLog"]] = relationship(  # type: ignore[name-defined]
        "MissionLog",
        back_populates="mission",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return (
            f"<Mission id={self.id} title={self.title!r}"
            f" freq={self.frequency!r} streak={self.current_streak}>"
        )
