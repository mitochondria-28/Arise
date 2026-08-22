import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base, UUIDMixin


class MissionLog(UUIDMixin, Base):
    """Immutable record of a single mission check-in."""

    __tablename__ = "mission_logs"

    mission_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("missions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    evidence_text: Mapped[str] = mapped_column(Text, nullable=False)
    reflection: Mapped[str | None] = mapped_column(Text, nullable=True)
    effort_level: Mapped[int] = mapped_column(Integer, nullable=False)
    xp_awarded: Mapped[int] = mapped_column(Integer, nullable=False)
    streak_at_checkin: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    mission: Mapped["Mission"] = relationship("Mission", back_populates="logs")  # type: ignore[name-defined]

    def __repr__(self) -> str:
        return (
            f"<MissionLog mission_id={self.mission_id}"
            f" xp={self.xp_awarded} streak={self.streak_at_checkin}>"
        )
